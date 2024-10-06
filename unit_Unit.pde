import java.util.Collections;

abstract class Unit {
    protected int q, r;
    protected float x, y;
    protected Civ civ;
    protected City city;
    protected UnitType type;
    protected PImage img;
    protected int moves;
    protected int visibilityBudget;
    
    protected int hp;
    protected boolean hasAttacked;

    protected boolean isLand;
    
    public Unit(int _q, int _r, float _x, float _y, UnitType _type, Civ _civ, City _city) {
        q = _q;
        r = _r;
        x = _x;
        y = _y;
        type = _type;
        civ = _civ;
        city = _city;
        updateColor();
    
        moves = _type.getMoves();
        visibilityBudget = _type.getVisibilityBudget();
        hp = 100;
        hasAttacked = false;

        isLand = _type.isLand();
    }

    public PImage getColorizedImg() {return img;}

    public int getQ() {return q;}
    public int getR() {return r;}
    public float getX() {return x;}
    public float getY() {return y;}
    public Civ getCiv() {return civ;}
    public City getCity() {return city;}
    public UnitType getType() {return type;}
    public AxialCoord getHex() {return new AxialCoord(q,r);}
    public Tile getTile() {return board.getTileAtCoord(getHex());}
    public boolean isLand() {return isLand;}
    public int getMoves() {return moves;}
    
    public void render() {
        unitG.beginDraw();
        unitG.blendMode(BLEND);
        unitG.translate(negOffsetX, negOffsetY);
        unitG.image(img, x, y+hexRadius*0.5, hexRadius*1.5, hexRadius*1.5);
        unitG.fill(0);
        for (int i=0; i<board.getUnitsAtCoord(getHex()).size(); i++) {
            PVector pos = new PVector(x+(hexRadius/2)-(hexRadius/2)*i, y);
            unitG.circle(pos.x, pos.y, hexRadius*0.5);
            unitG.image(board.getSecondaryUnit(getHex(), i), pos.x, pos.y , hexRadius*0.5, hexRadius*0.5);
        }
        if (hp < 100) {
            renderHealthBar();
        }
        unitG.endDraw();
    }

    public void updateColor() {
        PImage defaultImg = type.getImg();
        img = defaultImg.get();
        img.loadPixels();
        color primaryColor = civ.getPrimaryColor();

        for (int i = 0; i < img.pixels.length; i++) {
            int r = (img.pixels[i] >> 16) & 0xFF;  // Red value
            int g = (img.pixels[i] >> 8) & 0xFF;   // Green value
            int b = img.pixels[i] & 0xFF;          // Blue value
    
            // Check if each component is within the threshold of 255
            if (r >= 155 && g >= 155 && b >= 155) {
                img.pixels[i] = primaryColor;  // Change to red
            }
        }
    
        img.updatePixels();
    }

    public void heal() {
        if (hp < 100) {
            if (hp <= 80) {
                hp += 20;
            } else {
                hp = 100;
            }
            updateHealthBar();
        }
        // Adjust so +25 in home, +20 in friendly, +10 otherwise
    }
    
    public void renderHealthBar() {
        unitG.fill(0);
        unitG.rect(x-0.5*hexRadius, y+0.75*hexRadius, hexRadius, 10); // Draw the black background
        unitG.stroke(0);
        float healthWidth = map(hp, 0, 100, 0, hexRadius);
        float hue = map(hp, 0, 100, 0, 120); // 120 is green, 0 is red in HSB
        unitG.colorMode(HSB, 360, 100, 100);
        unitG.fill(hue, 100, 100);
        unitG.colorMode(RGB, 255, 255, 255);
        unitG.rect(x-0.5*hexRadius, y+0.75*hexRadius, healthWidth, 10); // Draw the health bar that depletes
    }
    
    public void updateHealthBar() {
        unitG.beginDraw();
        unitG.translate(negOffsetX, negOffsetY);
        unitG.blendMode(REPLACE);
        unitG.noStroke();
        unitG.fill(0,0);
        unitG.rect(x-0.5*hexRadius-1, y+0.75*hexRadius-1, hexRadius+2, 12);
        unitG.blendMode(BLEND);
        if (hp < 100) {
            renderHealthBar();
        } else {
            clearPosition();
            render();
        }
        unitG.endDraw();
    }

    private void clearPosition() {
        int radius = Math.round(hexRadius * 1.5f);
        int startX = Math.round(x - 0.5 * radius + negOffsetX);
        int startY = Math.round(y - 0.2 * radius + negOffsetY);
        
        unitG.beginDraw();
        unitG.blendMode(REPLACE);
        unitG.noStroke();
        unitG.fill(0, 0);
        unitG.rect(startX, startY, radius, radius);
        unitG.endDraw();
    }
    
    public void resetMoves() {
        moves = type.getMoves();
        hasAttacked = false;
    }

    public void seeNew() {
        Set<AxialCoord> visibleTileCoords = bfs(false).keySet();
        Set<AxialCoord> newCities = new HashSet<>(visibleTileCoords);
        Set<AxialCoord> newUnits = new HashSet<>(board.getUnitMapCoords());
        newUnits.retainAll(visibleTileCoords);
        newCities.retainAll(board.getCityMapCoords());
        for (AxialCoord coord : newCities) {
            City tempCity = board.getCityAtCoord(coord);
            Civ tempCiv = tempCity.getCiv();
            if (!civ.isCivKnown(tempCiv)) {
                civ.addKnownCiv(tempCiv);
            }
            if (!civ.isCityKnown(tempCity)) {
                civ.addKnownCity(city);
            }
        }
        for (AxialCoord coord : newUnits) {
            for (Unit unit : board.getUnitsAtCoord(coord)) {
                if (!civ.isCivKnown(unit.getCiv())) {
                    civ.addKnownCiv(unit.getCiv());
                }
            }
        }
    }
    
    public void addVisibleTiles() {
        Set<AxialCoord> visibleTileCoords = bfs(false).keySet();
        HashSet<Tile> visibleTileMap = new HashSet<>();
        for (AxialCoord coord : visibleTileCoords) {
            visibleTileMap.add(board.getTileAtCoord(coord));
        }
     
        civ.addVisibleTiles(visibleTileMap);
    }

    public AxialCoord getNearestFog() {
        Queue<AxialCoord> queue = new LinkedList<>();
        HashMap<AxialCoord, Integer> tempVisitedCost = new HashMap<>();

        queue.add(getHex());
        tempVisitedCost.put(getHex(), 0);
        while (!queue.isEmpty()) {
            AxialCoord current = queue.remove();
            int currentCost = tempVisitedCost.get(current);
            List<Tile> neighbours = board.getNeighbours(current.getQ(), current.getR());

            for (Tile neighbour : neighbours) {
                int newCost = currentCost + 1;
                AxialCoord neighbourHex = neighbour.getHex();
                if (!tempVisitedCost.containsKey(neighbourHex)) {
                    tempVisitedCost.put(neighbourHex, newCost);
                    if (!neighbour.getType().isVisibilityOccluder()) {
                        queue.add(neighbourHex);
                    }
                    if (!civ.getVisibleTiles().contains(neighbour)) {
                        return neighbourHex;
                    }
                }
            }
        }
        return null;
    }

    public void multiMove(AxialCoord target) {
        HashMap<AxialCoord, Integer> tempVisitedCost = bfs(true);

        if (!tempVisitedCost.containsKey(target)) {
            List<AxialCoord> path = aStar(target);
            if (isCoordReachable(target, true) && !path.isEmpty()) {
                HashMap<AxialCoord, Integer> moves = validMoves;
                if (moves.isEmpty()) {
                    moves = bfs(true);
                }

                for (int i=1; i<path.size()-1; i++) {
                    if (!moves.keySet().contains(path.get(i+1)) && moves.keySet().contains(path.get(i))) {
                        AxialCoord closestCoord = path.get(i);
                        if (embarkCoords.contains(closestCoord)) {
                            embark(closestCoord);
                        } else {
                            move(closestCoord, moves.get(closestCoord));
                        }
                    }
                }
            } else {
                if (!embarkCoords.contains(target)) {
                    Set<AxialCoord> extremities = new HashSet<>();
                    for (Map.Entry<AxialCoord, Integer> entry : tempVisitedCost.entrySet()) {
                        if (entry.getValue() == moves) {
                            extremities.add(entry.getKey());
                        }
                    }
                    extremities.addAll(embarkCoords);
                    
                    int closestDist = Integer.MAX_VALUE;
                    AxialCoord closestCoord = null;
                    for (AxialCoord coord : extremities) {
                        if (coord.dist(target) < closestDist) {
                            closestDist = coord.dist(target);
                            closestCoord = coord;
                        }
                    }
                    if (embarkCoords.contains(closestCoord)) {
                        embark(closestCoord);
                    } else {
                        move(closestCoord, moves);
                    }
                } else {
                    board.removeUnitToMultiMove(this);
                    embark(target);
                }
            }
        } else {
            move(target, tempVisitedCost.get(target));
            board.removeUnitToMultiMove(this);
        }
        embarkCoords = new HashSet<>();
    }

    public int estimateTurnsToMultiMove(AxialCoord target) {
        return ceil((aStar(target).size()-1)/type.getMoves())+1;
    }
    
    public void move(AxialCoord position, int cost) {
        board.removeUnit(getHex());
        civ.removeUnit(getHex());
        clearPosition();
        if (board.isUnitAtCoord(getHex())) {
            board.getFrontUnitAtCoord(getHex()).render();
        }
        
        City occupyingCity = board.getCityAtCoord(getHex());
        if (occupyingCity != null) {
            occupyingCity.setMarkerOffset(false);
        }
        q = position.getQ();
        r = position.getR();
        float[] posTuple = board.axialToCartesian(position);
        x = posTuple[0];
        y = posTuple[1];
        civ.setlastInteractedPos(x, y);
        clearPosition();
        board.addUnit(getHex(), this);
        civ.addUnit(getHex(), this);
        // Assuming hexWidth and hexHeight defined elsewhere or need to be calculated
        moves -= cost;
        addVisibleTiles();
        render();
        civ.renderUnknown();
        civ.maskUnknown();
        
        if (selectedUnit != null) {
            selectedUnit.deselect();
        }
        
        println("Unit moved to new position: (" + q + ", " + r + ") at cost: " + cost);
    }

    public void embark(AxialCoord position) {
        isLand = !isLand;
        move(position, moves);
    }
    
    public void delete() {
        deselect();
        board.unitMap.remove(getHex());
        thisCiv.removeUnit(getHex());
        clearPosition();
    }

    public List<AxialCoord> aStar(AxialCoord target) {
        PriorityQueue<Node> openSet = new PriorityQueue<>();
        Set<AxialCoord> closedSet = new HashSet<>();
        
        Node startNode = new Node(getHex(), 0, getHex().dist(target), null);
        openSet.add(startNode);

        while (!openSet.isEmpty()) {
            Node current = openSet.poll();
            AxialCoord currentHex = current.coord;
            if (currentHex.equals(target)) {
                return reconstructPath(current);
            }

            closedSet.add(currentHex);
            List<Tile> neighbours = board.getNeighbours(currentHex.getQ(), currentHex.getR());
            for (Tile neighbour : neighbours) {
                if (civ.getVisibleTiles().contains(neighbour)) {
                    AxialCoord neighbourHex = neighbour.getHex();
                    if (!board.isUnitAtCoord(neighbourHex)) {
                        if (closedSet.contains(neighbourHex)) {
                            continue;
                        }

                        float newGCost = current.gCost + (isLand ? neighbour.type.getTravelCost() : neighbour.type.getSeaTravelCost());
                        Node neighbourNode = new Node(neighbourHex, newGCost, neighbourHex.dist(target), current);
                        if (openSet.contains(neighbourNode)) {
                            continue;
                        }

                        openSet.add(neighbourNode);
                    }
                }
            }
        }
        return new ArrayList<>();
    }

    private List<AxialCoord> reconstructPath(Node node) {
        List<AxialCoord> path = new ArrayList<>();
        while (node != null) {
            path.add(node.coord);
            node = node.parent;
        }
        Collections.reverse(path);
        return path;
    }


    public boolean isCoordReachable(AxialCoord target, boolean withinReason) {
        Queue<Pair<AxialCoord, Integer>> queue = new LinkedList<>(); // Queue to hold coordinates and their depth
        Set<AxialCoord> visited = new HashSet<>(); // Set to track visited coordinates
        AxialCoord startHex = new AxialCoord(q, r);
        queue.add(new Pair<>(startHex, 0)); // Start with depth 0
        visited.add(startHex);

        while (!queue.isEmpty()) {
            Pair<AxialCoord, Integer> pair = queue.remove();
            AxialCoord current = pair.getKey();
            int currentDepth = pair.getValue();

            if (current.equals(target)) {
                return true; // Target is reachable
            }

            // Stop searching if maximum depth is exceeded
            int maxDepth = withinReason ? ceil(getHex().dist(target)*1.5) : 20;
            if (currentDepth >= maxDepth) {
                break; // Do not process further if the depth is 10 or more
            }

            List<Tile> neighbours = board.getNeighbours(current.getQ(), current.getR());
            for (Tile neighbour : neighbours) {
                if (civ.getVisibleTiles().contains(neighbour)) {
                    AxialCoord neighbourHex = neighbour.getHex();
                    if (!visited.contains(neighbourHex) && !board.getUnitMapCoords().contains(neighbourHex) && !neighbour.getType().isImpassable(isLand, true)) {
                        if (neighbourHex.equals(target)) {
                            return true; // Found the target
                        }
                        queue.add(new Pair<>(neighbourHex, currentDepth + 1));
                        visited.add(neighbourHex);
                    }
                }
            }
        }
        return false;
    }

    public abstract void select();
    public abstract void deselect();
    public abstract boolean takeDamage(AttackingUnit enemy);
    public abstract boolean takeDamage(City enemyCity);
    public abstract HashMap<AxialCoord, Integer> bfs(boolean isTravel);
    public void attack(Unit enemy) {
        // Default implementation does nothing or:
        throw new UnsupportedOperationException("This unit cannot attack.");
    }
    public void siege(City enemyCity) {
        // Default implementation does nothing or:
        throw new UnsupportedOperationException("This unit cannot siege.");
    }
}

class Node implements Comparable<Node> {
    AxialCoord coord;
    float gCost; // Cost from start node to this node
    float hCost; // Heuristic cost from this node to the goal
    Node parent;
    
    public Node(AxialCoord _coord, float g_cost, float h_cost, Node _parent) {
        coord = _coord;
        gCost = g_cost;
        hCost = h_cost;
        parent = _parent;
    }
    
    public float fCost() {return gCost + hCost;}
    
    @Override
    public int compareTo(Node other) {
        return Float.compare(this.fCost(), other.fCost());
    }
}

interface BfsStrategy {
    void processNode(AxialCoord current, int currentCost, Queue<AxialCoord> queue, HashMap<AxialCoord, Integer> visitedCost);
}

class PassiveTravelStrategy implements BfsStrategy {
    private Unit unit;

    PassiveTravelStrategy(Unit _unit) {
        this.unit = _unit;
    }

    @Override
    public void processNode(AxialCoord current, int currentCost, Queue<AxialCoord> queue, HashMap<AxialCoord, Integer> visitedCost) {
        List<Tile> neighbours = board.getNeighbours(current.getQ(), current.getR());
        for (Tile neighbour : neighbours) {
            int newCost = currentCost + (unit.isLand() ? neighbour.type.getTravelCost() : neighbour.type.getSeaTravelCost());
            AxialCoord neighbourHex = neighbour.getHex();
            //if (!visitedCost.containsKey(neighbourHex) && !board.getUnitMapCoords().contains(neighbourHex)) {
            if (!visitedCost.containsKey(neighbourHex) && board.isSimilarUnitAtCoord(neighbourHex, this.unit.getType())) {
                if (newCost <= unit.moves) {
                    queue.add(neighbourHex);
                    visitedCost.put(neighbourHex, newCost);
                } else if (unit.isLand() == neighbour.getType().isWater() && unit.moves-currentCost >= 1) {
                    embarkCoords.add(neighbourHex);
                }
            }
        }
    }
}

class VisibilityStrategy implements BfsStrategy {
    private Unit unit;

    VisibilityStrategy(Unit _unit) {
        this.unit = _unit;
    }

    @Override
    public void processNode(AxialCoord current, int currentCost, Queue<AxialCoord> queue, HashMap<AxialCoord, Integer> visitedCost) {
        List<Tile> neighbours = board.getNeighbours(current.getQ(), current.getR());
        for (Tile neighbour : neighbours) {
            int newCost = currentCost + neighbour.type.getVisibilityCost();
            AxialCoord neighbourHex = neighbour.getHex();
            if (newCost <= unit.visibilityBudget && !visitedCost.containsKey(neighbourHex)) {
                visitedCost.put(neighbourHex, newCost);
                if (!neighbour.getType().isVisibilityOccluder()) {
                    queue.add(neighbourHex);
                }
            }
        }
    }
}

public enum UnitClass {
    CIVILIAN, MELEE, RANGED;
}

public enum UnitType {
    SCOUT(3,4,UnitClass.MELEE,true,2), ARCHER(2,4,UnitClass.RANGED,true,3), SETTLER(2,3,UnitClass.CIVILIAN,true,0), WORKER(2,3,UnitClass.CIVILIAN,true,0), GALLEY(3,5,UnitClass.MELEE,false,3), QUAD(3,5,UnitClass.RANGED,false,3), TRADER(3,5,UnitClass.CIVILIAN,true,0), NONE(0,0,UnitClass.CIVILIAN,true,0);
    
    private PImage img;
    private int moves;
    private int visibilityBudget;
    private UnitClass unitClass;
    private boolean isLand;
    private int combatStrength;
    
    UnitType(int _moves, int _visibilityBudget, UnitClass _unitClass, boolean _isLand, int _combatStrength) {
        moves = _moves;
        visibilityBudget = _visibilityBudget;
        unitClass = _unitClass;
        isLand = _isLand;
        combatStrength = _combatStrength;
    }
    
    public PImage getImg() {return img;}
    public int getMoves() {return moves;}
    public int getVisibilityBudget() {return visibilityBudget;}
    public UnitClass getUnitClass() {return unitClass;}
    public boolean isLand() {return isLand;}
    public int getCombatStrength() {return combatStrength;}
    public void setImg(PImage _img) {img = _img;}
}