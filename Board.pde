import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.PriorityQueue;

class Board {
    public Map<AxialCoord, Tile> tileMap;
    private Map<AxialCoord, Stack<Unit>> unitMap;
    private Map<AxialCoord, City> cityMap;
    private State state;
    
    private Set<AxialCoord> cityTileCoords;
    private int turn;
    private int processedCivs;   // Unit map needs to be Map<

    private Set<Unit> unitsToAutomate;
    private Map<Unit, AxialCoord> unitsToMultiMove;

    PriorityQueue<TerrainTile> riverCandidates = new PriorityQueue<>(new ElevationComparator());
    HashMap<AxialCoord, TerrainTile> terrainMap = new HashMap<>();
    
    public Board() {
        tileMap = new HashMap<AxialCoord, Tile>();
        unitMap = new HashMap<AxialCoord, Stack<Unit>>();
        cityMap = new HashMap<AxialCoord, City>();
        state = State.GAME;
        
        cityTileCoords = new HashSet<AxialCoord>();
        turn = 0;
        processedCivs = 0;

        unitsToAutomate = new HashSet<Unit>();
        unitsToMultiMove = new HashMap<Unit, AxialCoord>();
    }
    
    public State getState() {return state;}
    public void setState(State newState) {state = newState;}
    public int getTurn() {return turn;}

    public void addUnitToAutomate(MeleeUnit unit) {
        unit.setAutomated(true);
        unitsToAutomate.add(unit);
    }
    public void addUnitToMultiMove(Unit unit, AxialCoord target) {unitsToMultiMove.put(unit, target);}
    public void removeUnitToMultiMove(Unit unit) {
        if (unit instanceof MeleeUnit) {
            if (((MeleeUnit) unit).isAutomated()) {
                unitsToAutomate.add(unit);
            }
            unitsToMultiMove.remove(unit);
        } else if (unit instanceof CivilianUnit) {
            if (((CivilianUnit) unit).getType() == UnitType.TRADER) {
                getCityAtCoord(unit.getHex()).dropOffTrade(((CivilianUnit) unit).getCarrying(), ((CivilianUnit) unit).getQuantity());
                AxialCoord cityCenter = unit.getCity().getHex();
                if (!unit.getHex().equals(cityCenter)) {
                    addUnitToMultiMove(unit, cityCenter);
                } else {
                    unitsToMultiMove.remove(unit);
                }
            } else {
                unitsToMultiMove.remove(unit);
            }
        }
    }
    public boolean isUnitMultiMove(Unit unit) {return unitsToMultiMove.containsKey(unit);}
    public void removeUnitToAutomate(Unit unit) {unitsToAutomate.remove(unit);}

    public void renderHover(AxialCoord coord) {
        float[] posTuple = axialToCartesian(coord);
        highlightG.beginDraw();
        highlightG.translate(negOffsetX, negOffsetY);
        highlightG.fill(0, 0, 255, 100);
        highlightG.noStroke();
        highlightG.beginShape();
        for (int i = 0; i < 6; i++) {
            float angle = TWO_PI / 6 * i;
            float radius = 2*hexRadius/3;
            float x = posTuple[0] + radius * cos(angle);
            float y = (posTuple[1] + 3*radius/4 + radius * sin(angle));
            highlightG.vertex(x, y);
        }
        highlightG.endShape(CLOSE);
        highlightG.fill(255);
        highlightG.textAlign(CENTER, CENTER);
        highlightG.textFont(font);
        highlightG.textSize(26);
        if (validMoves.containsKey(coord)) {
            int moves = validMoves.get(coord);
            if (moves != selectedUnit.getMoves()) {
                highlightG.text(moves, posTuple[0], posTuple[1]+hexRadius/3);
            } else {
                highlightG.text(moves+"X", posTuple[0], posTuple[1]+hexRadius/3);
            }
        } else if (embarkCoords.contains(coord)) {
            highlightG.text(selectedUnit.getMoves()+"X", posTuple[0], posTuple[1]+hexRadius/3);
        } else {
            highlightG.text(selectedUnit.estimateTurnsToMultiMove(coord)+"?", posTuple[0], posTuple[1]+hexRadius/3);
        }
        highlightG.endDraw();
    }

    public void clearHover(AxialCoord coord) {
        float[] posTuple = axialToCartesian(coord);
        highlightG.beginDraw();
        highlightG.blendMode(REPLACE);
        highlightG.translate(negOffsetX, negOffsetY);
        highlightG.fill(0, 0);
        highlightG.noStroke();
        highlightG.beginShape();
        for (int i = 0; i < 6; i++) {
            float angle = TWO_PI / 6 * i;
            float radius = 2*hexRadius/3;
            float x = posTuple[0] + radius * cos(angle);
            float y = (posTuple[1] + 3*radius/4 + radius * sin(angle));
            highlightG.vertex(x, y);
        }
        highlightG.endShape(CLOSE);
        highlightG.endDraw();
    }
    
    public void nextTurn() {     
        processedCivs++;
        if (processedCivs == civs.size()) {
            turn++;
            for (Unit unit : getUnitMapUnits()) {
                unit.seeNew();
                unit.resetMoves();
                unit.heal();
            }
            for (Map.Entry<Unit, AxialCoord> unitAndTarget : unitsToMultiMove.entrySet()) {
                Unit unit = unitAndTarget.getKey();
                unit.multiMove(unitAndTarget.getValue());
            }
            for (Unit unit : unitsToAutomate) {
                ((MeleeUnit) unit).automate();
            }
            for (City city : cityMap.values()) {
                city.decrementTurnsToProduce();
                city.applyPT();
                city.heal();
                city.seeNew();
                city.checkBombard();
            }
            processedCivs = 0;
        }
        thisCiv = turnOrder.get(processedCivs);
        deselectUnits();
        thisCiv.snapToUnit();
        thisCiv.maskUnknown();
    }
    
    public void deselectUnits() {
        selectedUnit = null;
        validMoves = new HashMap<>();
        highlightG.beginDraw();
        highlightG.clear();
        highlightG.endDraw();
        
        gui.hide(GUIType.SETTLE);
        gui.hide(GUIType.AUTOMATE);
    }
    
    private Biome determineBiome(float elevation, float moisture, float temperature) {
        for (BiomeRule rule : biomeRules) {
            if (rule.matches(elevation, moisture, temperature)) {
                return rule.biome;
            }
        }
        return null;
    }
    
    private Tile formTile(int q, int r, float x, float y, Biome biome, float elevation, float moisture) {
        List<TerrainTileRule> rules = terrainTileRules.get(biome);
        if (rules != null) {
            for (TerrainTileRule rule : rules) {
                if (rule.matches(elevation, moisture)) {
                    ResourceType resource = null;
                    if (random.nextDouble() > 0.8) {
                        switch (rule.getType()) {
                            case GRASSLAND:
                            case SPARSE_FOREST_GRASSLAND:
                                if (moisture > 0.5) {
                                    resource = ResourceType.COTTON;
                                } else {
                                    resource = ResourceType.HORSES;
                                }
                                break;
                            case HILL_GRASSLAND:
                            case MOUNTAIN:
                            case FORESTED_HILL_GRASSLAND:
                                if (elevation > 0.7) {
                                    resource = ResourceType.IRON;
                                }
                                break;
                            case MARSH_GRASS:
                                if (moisture > 0.6) {
                                    resource = ResourceType.COTTON;
                                }
                                break;
                            default:
                                break;
                        }
                    }
                    AxialCoord coord = new AxialCoord(q, r);
                    terrainMap.put(coord, new TerrainTile(coord, elevation, biome));
                    return new Tile(q, r, x, y, biome, rule.getType(), resource);
                }
            }
        }
        return null;
    }
    
    private void tileHandler(int q, int r, float x, float y) {
        float elevation = noise(q * noiseScale, r * noiseScale);
        float moisture = noise(q * noiseScale + 10000, r * noiseScale + 10000);
        float temperature = noise(q * noiseScale + 50000, r * noiseScale + 50000);
        Biome biome = determineBiome(elevation, moisture, temperature);
        Tile tile = formTile(q, r, x, y, biome, elevation, moisture);
        
        AxialCoord coord = new AxialCoord(q, r);
        tileMap.put(coord, tile);
        //if (random.nextDouble() > 1-elevation) {
        riverCandidates.add(new TerrainTile(coord, elevation, biome));
        if (riverCandidates.size() >= round(bs/2)) {
            riverCandidates.poll();
        }
        tile.render();
    }

    private <T> T getRandomElement(Set<T> set) {
        int size = set.size();
        int itemIndex = random.nextInt(size); // Generate a random index
        int i = 0;
        for (T obj : set) {
            if (i == itemIndex)
                return obj;
            i++;
        }
        return null; // only returns null if the set is empty
    }

    public void generateBoard() {
        float hexHeight = hexRadius * (1.5 / sqrt_3);  // Pre-calculate constant height adjustment
        float hexWidth = 1.5 * hexRadius;  // Pre-calculate constant width adjustment
        float shiftX = 3 * hexRadius;  // Pre-calculate constant X shift per row
        
        int centerY = height / 2;
        int centerX = width / 2;
        
        float startX = centerX - (bs - 1) * hexWidth - (bs - 1) * shiftX;
        float startY = centerY - (bs - 1) * hexHeight;
        
        boardG.beginDraw();
        boardG.translate(negOffsetX, negOffsetY);
        boardG.noStroke();
        boardG.fill(#000066);
        for (int i = -2; i < bs-1; i++) {
            float x = startX + i * hexWidth + shiftX;
            float y = startY + i * hexHeight;
            hexagon(boardG, x, y, false);
        }
        int r = -bs + 1;
        for (int j = 0; j < bs; j++) {
            int q = -r-bs+1;
            float edgeX = startX + (j-1) * hexWidth - j * shiftX;
            float edgeY = startY + (j-1) * hexHeight;
            hexagon(boardG, edgeX, edgeY, false);
            for (int i = j; i < bs + 2 * j; i++) {
                float x = startX + i * hexWidth - j * shiftX;
                float y = startY + i * hexHeight;
                tileHandler(q, r, x, y);
                q++;
            }
            edgeX = startX + (bs + 2 * j) * hexWidth - j * shiftX;
            edgeY = startY + (bs + 2 * j) * hexHeight;
            hexagon(boardG, edgeX, edgeY, false);
            r++;
        }
        // Adjust starting point for contracting pattern
        startX += (bs - 1) * hexWidth - (bs - 1) * shiftX;
        startY += (bs - 1) * hexHeight;
        for (int j = 0; j < bs - 1; j++) {
            int q = -bs+1;
            float edgeX = startX + hexWidth - shiftX;
            float edgeY = startY + (1 + 2 * j) * hexHeight;
            hexagon(boardG, edgeX, edgeY, false);
            for (int i = 0; i < bs * 2 - 2 - j; i++) {
                float x = startX + (i + 2) * hexWidth - shiftX;
                float y = startY + (i + 2 + 2 * j) * hexHeight;
                tileHandler(q, r, x, y);
                q++;
            }
            edgeX = startX + (bs * 2 - j) * hexWidth - shiftX;
            edgeY = startY + (bs * 2 + j) * hexHeight;
            hexagon(boardG, edgeX, edgeY, false);
            r++;
        }
        for (int i = -1; i < bs; i++) {
            float x = startX + (i + 2) * hexWidth - shiftX;
            float y = startY + (i + 2 * bs) * hexHeight;
            hexagon(boardG, x, y, false);
        }

        // Contracting pattern if needed here
        Set<AxialCoord> visited = new HashSet<>();
        Set<ArrayList<AxialCoord>> rivers = new HashSet<>();
        Map<AxialCoord, List<AxialCoord>> waterJoins = new HashMap<>();

        int riverCnt = riverCandidates.size();
        for (int i=0; i<riverCnt; i++) {
            ArrayList<AxialCoord> riverCoords = new ArrayList<>();

            TerrainTile current = riverCandidates.poll();
            AxialCoord currentCoord = current.getCoord(); 
            riverCoords.add(currentCoord);
            visited.add(currentCoord);
            float currentElevation = current.getElevation();
            Biome currentBiome = current.getBiome();

            while (currentElevation > 0.2) {
                List<TerrainTile> lowerTiles = new ArrayList<TerrainTile>();

                for (AxialCoord dir : new AxialCoord[]{new AxialCoord(-1, 0), new AxialCoord(-1, 1), new AxialCoord(1, -1), new AxialCoord(1, 0)}) { //Can be substitued with directions, if willing to code other junctions
                    int newQ = currentCoord.getQ() + dir.getQ();
                    int newR = currentCoord.getR() + dir.getR();
                    AxialCoord coord = new AxialCoord(newQ, newR);

                    if (board.isWithinBounds(newQ, newR)) {
                        TerrainTile newTile = terrainMap.get(coord);
                        float newElevation = newTile.getElevation();

                        if (newElevation < currentElevation+0.1 && !riverCoords.contains(coord)) {
                            lowerTiles.add(newTile);
                        }
                    }
                }
                if (!lowerTiles.isEmpty()) {
                    TerrainTile randomTile = lowerTiles.get(random.nextInt(lowerTiles.size()));
                    Biome lowestBiome = randomTile.getBiome();
                    AxialCoord lowestCoord = randomTile.getCoord();
                    float lowestElevation = randomTile.getElevation();

                    if (lowestBiome != Biome.LAKE && lowestBiome != Biome.OCEAN) {
                        if (visited.contains(lowestCoord)) { // Join on main river
                            addToMap(waterJoins, lowestCoord, new AxialCoord(currentCoord.getQ()-lowestCoord.getQ(), currentCoord.getR()-lowestCoord.getR()));
                            addToMap(waterJoins, currentCoord, new AxialCoord(lowestCoord.getQ()-currentCoord.getQ(), lowestCoord.getR()-currentCoord.getR()));
                            break;
                        } else {
                            currentCoord = lowestCoord;
                            currentElevation = lowestElevation;
                            currentBiome = lowestBiome;

                            visited.add(currentCoord);
                            riverCoords.add(currentCoord);
                        }
                    } else {
                        addToMap(waterJoins, currentCoord, new AxialCoord(lowestCoord.getQ()-currentCoord.getQ(), lowestCoord.getR()-currentCoord.getR()));
                        break;
                    }
                } else {
                    break;
                }
            }
            rivers.add(riverCoords);
        }

        for (ArrayList<AxialCoord> river : rivers) {
            for (int i=0; i<river.size(); i++) {
                AxialCoord coord = river.get(i);
                Tile tile = getTileFromCoords(coord.getQ(), coord.getR());
                if (tile.getType() != TileType.MOUNTAIN && tile.getType() != TileType.CLIFF_SAND) {
                    AxialCoord prevCoord = null;
                    AxialCoord nextCoord = null;
                    Set<AxialCoord> vectors = new HashSet<>();
                    if (i > 0) {
                        prevCoord = river.get(i-1);
                        vectors.add(new AxialCoord(prevCoord.getQ() - coord.getQ(), prevCoord.getR() - coord.getR()));
                    }
                    if (i < river.size()-1) {
                        nextCoord = river.get(i+1);
                        vectors.add(new AxialCoord(nextCoord.getQ() - coord.getQ(), nextCoord.getR() - coord.getR()));
                    }
                    if (waterJoins.containsKey(coord)) {
                        vectors.addAll(waterJoins.get(coord));
                    }

                    float[] posTuple = axialToCartesian(coord);

                    int index = -1;
                    if (vectors.containsAll(Arrays.asList(new AxialCoord[]{new AxialCoord(-1, 0), new AxialCoord(1, -1), new AxialCoord(-1, 1), new AxialCoord(1, 0)}))) {
                        index = 8;
                    } else if (vectors.containsAll(Arrays.asList(new AxialCoord[]{new AxialCoord(-1, 0), new AxialCoord(-1, 1), new AxialCoord(1, 0)}))) {
                        index = 16;
                    } else if (vectors.containsAll(Arrays.asList(new AxialCoord[]{new AxialCoord(-1, 1), new AxialCoord(1, 0), new AxialCoord(1, -1)}))) {
                        index = 17;
                    } else if (vectors.containsAll(Arrays.asList(new AxialCoord[]{new AxialCoord(-1, 0), new AxialCoord(-1, 1), new AxialCoord(1, -1)}))) {
                        index = 18;
                    } else if (vectors.containsAll(Arrays.asList(new AxialCoord[]{new AxialCoord(-1, 0), new AxialCoord(1, -1), new AxialCoord(1, 0)}))) {
                        index = 19;
                    } else if (vectors.contains(new AxialCoord(0, -1))) {
                        if (vectors.contains(new AxialCoord(1, -1))) {
                            index = 15;
                        } else if (vectors.contains(new AxialCoord(1, 0))) {
                            index = 2;
                        } else if (vectors.contains(new AxialCoord(0, 1))) {
                            index = 3;
                        } else if (vectors.contains(new AxialCoord(-1, 1))) {
                            index = 5;
                        } else if (vectors.contains(new AxialCoord(-1, 0))) {
                            index = 7;
                        } else {
                            index = 3;
                        }
                    } else if (vectors.contains(new AxialCoord(1, -1))) {
                        if (vectors.contains(new AxialCoord(0, -1))) {
                            index = 15;
                        } else if (vectors.contains(new AxialCoord(1, 0))) {
                            index = 12;
                        } else if (vectors.contains(new AxialCoord(0, 1))) {
                            index = 0;
                        } else if (vectors.contains(new AxialCoord(-1, 1))) {
                            index = 9;
                        } else if (vectors.contains(new AxialCoord(-1, 0))) {
                            index = 14;
                        } else {
                            index = 9;
                        }
                    } else if (vectors.contains(new AxialCoord(1, 0))) {
                        if (vectors.contains(new AxialCoord(0, -1))) {
                            index = 2;
                        } else if (vectors.contains(new AxialCoord(1, -1))) {
                            index = 12;
                        } else if (vectors.contains(new AxialCoord(0, 1))) {
                            index = 1;
                        } else if (vectors.contains(new AxialCoord(-1, 1))) {
                            index = 13;
                        } else if (vectors.contains(new AxialCoord(-1, 0))) {
                            index = 10;
                        } else {
                            index = 10;
                        }
                    } else if (vectors.contains(new AxialCoord(0, 1))) {
                        if (vectors.contains(new AxialCoord(0, -1))) {
                            index = 3;
                        } else if (vectors.contains(new AxialCoord(1, -1))) {
                            index = 0;
                        } else if (vectors.contains(new AxialCoord(1, 0))) {
                            index = 1;
                        } else if (vectors.contains(new AxialCoord(-1, 1))) {
                            index = 4;
                        } else if (vectors.contains(new AxialCoord(-1, 0))) {
                            index = 6;
                        } else {
                            index = 3;
                        }
                    } else if (vectors.contains(new AxialCoord(-1, 1))) {
                        if (vectors.contains(new AxialCoord(0, -1))) {
                            index = 5;
                        } else if (vectors.contains(new AxialCoord(1, -1))) {
                            index = 9;
                        } else if (vectors.contains(new AxialCoord(1, 0))) {
                            index = 13;
                        } else if (vectors.contains(new AxialCoord(0, 1))) {
                            index = 4;
                        } else if (vectors.contains(new AxialCoord(-1, 0))) {
                            index = 11;
                        } else {
                            index = 9;
                        }
                    } else if (vectors.contains(new AxialCoord(-1, 0))) {
                        if (vectors.contains(new AxialCoord(0, -1))) {
                            index = 7;
                        } else if (vectors.contains(new AxialCoord(1, -1))) {
                            index = 14;
                        } else if (vectors.contains(new AxialCoord(1, 0))) {
                            index = 10;
                        } else if (vectors.contains(new AxialCoord(0, 1))) {
                            index = 6;
                        } else if (vectors.contains(new AxialCoord(-1, 1))) {
                            index = 11;
                        } else {
                            index = 10;
                        }
                    }

                    boardG.image(trailImgs[index], posTuple[0], posTuple[1], hexRadius*2, hexRadius*3);
                    tile.addRiver();
                }
            }
        }
    
        boardG.endDraw();
    }

    public Set<AxialCoord> getCoordsWithinRange(AxialCoord coord, int range) {
        Set<AxialCoord> results = new HashSet<>();
        for (int q = -range; q <= range; q++) {
            for (int r = max(-range, -q-range); r <= min(range, -q+range); r++) {
                int newQ = coord.getQ() + q;
                int newR = coord.getR() + r;
                if (isWithinBounds(newQ, newR)) {
                    results.add(new AxialCoord(newQ, newR));
                }
            }
        }
        return results;
    }
    
    public Tile getTileFromCoords(int q, int r) {
        return tileMap.get(new AxialCoord(q, r));
    }
    
    public float[] axialToCartesian(AxialCoord coord) {
        Tile tile = tileMap.get(coord);
        return new float[]{tile.getX(), tile.getY()};
    }
    
    public boolean isCoordAccessible(AxialCoord coord, boolean isLand, boolean canEmbark) {
        return isWithinBounds(coord.getQ(), coord.getR()) && !isUnitAtCoord(coord) && getCityAtCoord(coord) == null && !getTileAtCoord(coord).getType().isImpassable(isLand, canEmbark);
    }

    public ArrayList<Tile> getTileMapTiles() {
        return new ArrayList<>(tileMap.values());
    }
    
    public Set<Unit> getUnitMapUnits() {
        Set<Unit> units = new HashSet<>();
        for (Stack<Unit> unitList : unitMap.values()) {
            units.addAll(unitList);
        }
        return units;
    }
    
    public ArrayList<City> getCityMapCities() {
        return new ArrayList<>(cityMap.values());
    }
    
    public Tile getTileAtCoord(AxialCoord coord) {
        return tileMap.get(coord);
    }
    
    public Stack<Unit> getUnitsAtCoord(AxialCoord coord) {
        return unitMap.get(coord);
    }

    public PImage getSecondaryUnit(AxialCoord coord, int index) {
        return unitMap.get(coord).get(index).getColorizedImg();
    }

    public boolean isUnitAtCoord(AxialCoord coord) {
        return unitMap.containsKey(coord);
    }
    
    public Unit getFrontUnitAtCoord(AxialCoord coord) {
        if (unitMap.containsKey(coord)) {
            return unitMap.get(coord).peek();
        } else {
            return null;
        }
    }

    public void setUnitsAtCoord(AxialCoord coord, Stack<Unit> units) {
        unitMap.put(coord, units);
    }
    
    public City getCityAtCoord(AxialCoord coord) {
        return cityMap.get(coord);
    }
    
    public Set<AxialCoord> getUnitMapCoords() {
        return unitMap.keySet();
    }

    public boolean isSimilarUnitAtCoord(AxialCoord coord, UnitType type) {
        if (type == UnitType.TRADER || !unitMap.containsKey(coord)) {
            return true;
        }
        UnitClass unitClass = type.getUnitClass();
        for (Unit unit : unitMap.get(coord)) {
            if (unit.getType().getUnitClass() == unitClass) {
                return true;
            }
        }
        return false;
    }
    
    public Set<AxialCoord> getCityMapCoords() {
        return cityMap.keySet();
    }
    
    public void addCity(AxialCoord coord, City city) {
        cityMap.put(coord, city);
    }
    
    public void addUnit(AxialCoord coord, Unit unit) {
        addToMapStack(unitMap, coord, unit);
    }
    
    public void removeUnit(AxialCoord coord) {
        popFromStack(unitMap, coord);
        if (unitMap.containsKey(coord) && !unitMap.get(coord).isEmpty()) {
            unitMap.get(coord).peek().render();
        }
    }
    
    public void addCityTileCoords(Set<AxialCoord> newCityTileCoords) {
        cityTileCoords.addAll(newCityTileCoords);
    }
    
    public boolean isTileCoordInCity(AxialCoord coord) {
        return cityTileCoords.contains(coord);
    }

    public boolean isWithinBounds(int q, int r) {
        // Calculate the implicit third coordinate s
        return Math.max(Math.max(abs(q), abs(r)), abs(-q-r)) <= bs-1;
    }

    public List<Tile> getNeighbours(int customQ, int customR) {
        List<Tile> neighbours = new ArrayList<>();
        for (AxialCoord dir : directions) {
            int newQ = customQ + dir.getQ();
            int newR = customR + dir.getR();
            if (board.isWithinBounds(newQ, newR)) {
                Tile neighbour = board.getTileFromCoords(newQ, newR);
                if (neighbour != null) {
                    neighbours.add(neighbour);
                }
            }
        }
        return neighbours;
    }

    public List<AxialCoord> getNeighbourCoords(AxialCoord coord) {
        List<AxialCoord> neighbours = new ArrayList<>();
        for (AxialCoord dir : directions) {
            int newQ = coord.getQ() + dir.getQ();
            int newR = coord.getR() + dir.getR();
            if (board.isWithinBounds(newQ, newR)) {
                neighbours.add(coord);
            }
        }
        return neighbours;
    }
    
    public boolean validTile(Tile tile) {
        boolean validBiome = tile.getBiome() != Biome.OCEAN && tile.getBiome() != Biome.LAKE && tile.getBiome() != Biome.MOUNTAIN;
        boolean freeSpace = !isUnitAtCoord(tile.getHex());
        return validBiome && freeSpace;
    }
    
    private AxialCoord getSpawnCoordsAndSpawn(UnitType spawner, Civ civ, int unitsToSpawn) {
        List<Tile> valuesList = getTileMapTiles();  // Assume this does not change per loop iteration
        Tile randomTile = null;  // Declare outside to use after the loop
        
        while (true) {
            randomTile = valuesList.get(random.nextInt(valuesList.size()));
            //randomTile = board.getTileFromCoords(0,-9);
            if (!validTile(randomTile)) {
                valuesList.remove(randomTile);
            } else {
                int validNeighboursCnt = 0;
                for (AxialCoord dir : directions) {
                    int newQ = randomTile.getQ() + dir.getQ();
                    int newR = randomTile.getR() + dir.getR();
                    if (board.isWithinBounds(newQ, newR) && validTile(board.getTileFromCoords(newQ, newR))) {
                        validNeighboursCnt++;
                    }
                }
                if (validNeighboursCnt >= unitsToSpawn) {
                    break;
                } else {
                    valuesList.remove(randomTile);
                }
            }
        }
        if (!valuesList.isEmpty()) {
            //thisCiv.getType()
            Unit unit = createUnit(randomTile.getQ(), randomTile.getR(), randomTile.getX(), randomTile.getY(), spawner, civ, null);
            addToMapStack(unitMap, randomTile.getHex(), unit);
            civ.addUnit(randomTile.getHex(), unit);
            
            unit.render();
            snapCamera(unit.getX(), unit.getY());
            return randomTile.getHex();
        }
        return null;
    }
    
    private int spawnUnit(UnitType type, Civ civ, AxialCoord spawn, int startDirIndex) {
        for (int i=startDirIndex; i<directions.length; i++) {
            AxialCoord dir = directions[i];
            int newQ = spawn.getQ() + dir.getQ();
            int newR = spawn.getR() + dir.getR();
            Tile tileAtCoord = getTileFromCoords(newQ, newR);
            if (board.isWithinBounds(newQ, newR) && tileAtCoord != null) {
                if (validTile(tileAtCoord)) {
                    Unit unit = createUnit(newQ, newR, tileAtCoord.getX(), tileAtCoord.getY(), type, civ, null);
                    addToMapStack(unitMap, new AxialCoord(newQ, newR), unit);
                    civ.addUnit(new AxialCoord(newQ, newR), unit);
                    
                    unit.render();
                    return i+1;
                }
            }
        }
        return 6; // All directions cycled through
    }
    
    private void spawnSequence(ArrayList<UnitType> list, Civ civ) {
        int dirIndex = 0;
        for (UnitType type : list) {
            if (dirIndex < 6) {
                dirIndex = spawnUnit(type, civ, civ.getSpawnCoord(), dirIndex);
            } else {
                break;
            }
        }
    }
    
    public void spawn(Civ civ) {
        ArrayList<UnitType> spawnList = new ArrayList<>();
        spawnList.add(UnitType.SCOUT);
        spawnList.add(UnitType.TRADER);
        civ.setSpawnCoord(getSpawnCoordsAndSpawn(UnitType.SETTLER, civ, spawnList.size()));
        spawnSequence(spawnList, civ);
    }

    public Unit createUnit(int q, int r, float x, float y, UnitType type, Civ civ, City city) {
        if (type.getUnitClass() == UnitClass.CIVILIAN) {
            return new CivilianUnit(q, r, x, y, type, civ, city);
        } else if (type.getUnitClass() == UnitClass.MELEE) {
            return new MeleeUnit(q, r, x, y, type, civ, city);
        } else if (type.getUnitClass() == UnitClass.RANGED) {
            return new RangedUnit(q, r, x, y, type, civ, city);
        }
        return null;
    }
}

public enum YieldType {
    SCIENCE, GOLD, FOOD, CULTURE, TOURISM, PRODUCTION, HAPPINESS;
}

public enum State {
    GAME, PRODUCTION, RESEARCH, DEMOGRAPHICS, TRADER;
}