import java.util.Collection;
import java.lang.Math;

class Civ {
    private CivName type;
    private City capital;
    private AxialCoord spawnCoord;
    private HashMap<AxialCoord, Stack<Unit>> civUnitMap;
    private Set<Tile> tiles;
    private Set<Tile> visibleTiles;
    private Set<City> cities;
    private PImage icon;
    private color primaryColor, secondaryColor;
    private String[] cityNames;
    private HashMap<AxialCoord, Stack<PVector>> secondaryUnitHitboxes;
    private HashMap<PVector, City> cityBombardHitboxes;
    
    public PGraphics civKnownMaskG;
    public PGraphics civCityMarkerG;
    public PGraphics civHUDG;
    
    private int gold;
    private int goldPT;
    private int happiness;
    private int science;
    private int sciencePT;
    private int culture;
    private int culturePT;

    private int productionPT;
    private int foodPT;

    private HashMap<Civ, RelationshipState> knownCivs;
    private Set<City> knownCities;

    private PVector lastInteractedPos;

    private Set<ResourceType> luxuryResources;
    private Tech researching;

    private TechTree techTree;

    private HashMap<Tech, TechState> techStates;
    ArrayList<TechOption> techOptions = new ArrayList<TechOption>();
    private Era era;
    
    public Civ(CivName _type) {
        type = _type;
        capital = null;
        icon = _type.getIcon();
        primaryColor = _type.getPrimaryColor();
        secondaryColor = _type.getSecondaryColor();
        cityNames = _type.getCityNames();
        spawnCoord = null;
        civUnitMap = new HashMap<AxialCoord, Stack<Unit>>();
        tiles = new HashSet<Tile>();
        visibleTiles = new HashSet<Tile>();
        cities = new HashSet<City>();
        knownCivs = new HashMap<Civ, RelationshipState>();
        knownCivs.put(this, RelationshipState.NEUTRAL);
        knownCities = new HashSet<City>();
        lastInteractedPos = null;
        secondaryUnitHitboxes = new HashMap<AxialCoord, Stack<PVector>>();
        cityBombardHitboxes = new HashMap<PVector, City>();
         
        gold = 0;
        goldPT = 0;
        happiness = 0;
        science = 0;
        sciencePT = 1000;
        culture = 0;
        culturePT = 0;

        luxuryResources = new HashSet<ResourceType>();
        researching = null;

        techStates = new HashMap<Tech, TechState>();
        for (Tech tech : Tech.values()) {
            techStates.put(tech, TechState.UNAVAILABLE);
        }
        era = Era.ANCIENT;

        techStates.put(Tech.AGRICULTURE, TechState.RESEARCHED);

        techTree = new TechTree();
    }

    public TechState getTechState(Tech tech) {
        return techStates.get(tech);
    }

    public int getResearchingCol() {
        if (researching != null) {
            return researching.getCol();
        } else {
            return -1;
        }
    }

    public TechState getResearchingState() {
        return techStates.get(researching);
    }
    
    public void initCityBoundariesG() {
        cityBoundariesG = createGraphics(boardLengthX, boardLengthY, P2D);
    }
    
    public void initKnownMaskG() {
        civKnownMaskG = createGraphics(boardLengthX, boardLengthY, P2D);
    }
    
    public void initCityMarkerG() {
        civCityMarkerG = createGraphics(boardLengthX, boardLengthY, P2D);
    }
    
    public void initHUDG() {
        civHUDG = createGraphics(boardLengthX, boardLengthY, P2D);
    }
    
    public PGraphics getKnownMaskG() {return civKnownMaskG;}
    public PGraphics getCityMarkerG() {return civCityMarkerG;}
    public PGraphics getHUDG() {return civHUDG;}
    
    public CivName getType() {return type;}
    public color getPrimaryColor() {return primaryColor;}
    public color getSecondaryColor() {return secondaryColor;}
    public AxialCoord getSpawnCoord() {return spawnCoord;}
    public Set<Unit> getCivUnitMapUnits() {
        Set<Unit> units = new HashSet<>();
        for (Stack<Unit> queue : civUnitMap.values()) {
            units.addAll(queue);
        }
        return units;
    }
    public City getCapital() {return capital;}
    public PImage getIcon() {return icon;}
    public Set<Tile> getTiles() {return tiles;}
    public Set<Tile> getVisibleTiles() {return visibleTiles;}
    
    public void setSpawnCoord(AxialCoord _spawnCoord) {
        spawnCoord = _spawnCoord;
        float[] posTuple = board.axialToCartesian(_spawnCoord);
        lastInteractedPos = new PVector(posTuple[0], posTuple[1]);
    }
    public void setCapital(City city) {capital = city;}

    public void addGoldPT(int amount) {
        goldPT += amount;
        updateHUD();
    }
    public void addProductionPT(int amount) {productionPT += amount;}
    public void addFoodPT(int amount) {foodPT += amount;}

    public void addResource(ResourceType resource) {
        if (!luxuryResources.contains(resource)) {
            luxuryResources.add(resource);
            happiness += 4;
            updateHUD();
        }
    }

    public Set<Civ> getCivs(RelationshipState ofState) {
        Set<Civ> civs = new HashSet<Civ>();
        for (Map.Entry<Civ, RelationshipState> entry : knownCivs.entrySet()) {
            if (entry.getValue() == ofState) {
                civs.add(entry.getKey());
            }
        }
        return civs;
    }

    public RelationshipState getRelationship(Civ civ) {
        return knownCivs.get(civ);
    }

    public void firstRenderTechTree() {
        board.setState(State.RESEARCH);
        gui.hide(GUIType.RESEARCH);
        gui.hide(GUIType.NEXTTURN);
        gui.show(GUIType.CLOSERESEARCH, true);
        scrollFactor = 0;
        renderTechTree();
    }

    public void renderTechTree() {
        techTree.drawOptions();
    }

    public void closeResearch() {
        techTree.close();
    }

    public Set<ResourceType> getLuxuryResources() {return luxuryResources;}
    
    public void addVisibleTiles(HashSet<Tile> newVisibleTiles) {
        visibleTiles.addAll(newVisibleTiles);
        Set<AxialCoord> newCoords = new HashSet<AxialCoord>();
        for (Tile tile : newVisibleTiles) {
            newCoords.add(tile.getHex());
        }
        Set<AxialCoord> newCities = new HashSet<>(newCoords);
        Set<AxialCoord> newUnits = new HashSet<>(board.getUnitMapCoords());
        newUnits.retainAll(newCoords);
        newCities.retainAll(board.getCityMapCoords());
        for (AxialCoord coord : newCities) {
            City city = board.getCityAtCoord(coord);
            Civ civ = city.getCiv();
            if (!knownCivs.containsKey(civ)) {
                //knownCivs.put(civ, RelationshipState.NEUTRAL); For normal
                knownCivs.put(civ, RelationshipState.WAR);
            }
            if (!knownCities.contains(city)) {
                knownCities.add(city);
            }
        }
        for (AxialCoord coord : newUnits) {
            for (Unit unit : board.getUnitsAtCoord(coord)) {
                if (!knownCivs.containsKey(unit.getCiv())) {
                    knownCivs.put(unit.getCiv(), RelationshipState.WAR);
                }
            }
        }
    }
    public void addKnownCiv(Civ civ) {
        knownCivs.put(civ, RelationshipState.WAR);
    }

    public boolean isCivKnown(Civ civ) {
        return knownCivs.containsKey(civ);
    }

    public boolean isCityKnown(City city) {
        return knownCities.contains(city);
    }

    public void addCityBombardHitbox(PVector pos, City city) {
        cityBombardHitboxes.put(pos, city);
    }

    public void removeCityBombardHitbox(PVector pos) {
        if (cityBombardHitboxes.containsKey(pos)) {
            cityBombardHitboxes.remove(pos);
        }
    }

    public HashMap<PVector, City> getCityBombardHitboxes() {
        return cityBombardHitboxes;
    }

    public Set<City> getKnownCities() {return knownCities;}
    public Set<City> getFriendlyCities() {
        Set<City> friendlyCities = new HashSet<City>();
        for (City city : knownCities) {
            if (knownCivs.get(city.getCiv()).isFriendly()) {
                friendlyCities.add(city);
            }
        }
        return friendlyCities;
    }

    public void addTiles(HashSet<Tile> newTiles) {
        tiles.addAll(newTiles);
    }
    
    public boolean isTileInCiv(Tile tile) {
        return tiles.contains(tile);
    }
    
    public City getCityOfCoord(AxialCoord coord) {
        for (City city : cities) {
            if (city.getTileCoords().contains(coord)) {
                return city;
            }
        }
        return null;
    }

    public City isTileCity(AxialCoord coord) {
        for (City city : cities) {
            if (city.getHex().equals(coord)) {
                return city;
            }
        }
        return null;
    }
    
    public void renderVisibleCityMarkers(Set<Tile> newTiles) {
        for (Tile tile : newTiles) {
            City city = board.getCityAtCoord(tile.getHex());
            if (city != null) {
                if (city.getCiv() != this) {
                    city.drawForeignCityMarker(this.civCityMarkerG);
                }
            }
        }
    }
    
    public void renderVisibleCityMarkers() {
        for (Tile tile : visibleTiles) {
            City city = board.getCityAtCoord(tile.getHex());
            if (city != null) {
                if (city.getCiv() != this) {
                    city.drawForeignCityMarker(this.civCityMarkerG);
                }
            }
        }
    }
    
    public void renderUnknown() {
        long startTime = System.currentTimeMillis();
        civKnownMaskG.beginDraw();
        println("Time to clear: "+(System.currentTimeMillis()-startTime));
        civKnownMaskG.translate(negOffsetX, negOffsetY);
        civKnownMaskG.background(255);
        civKnownMaskG.fill(0);
        civKnownMaskG.noStroke();
        for (Tile tileToClear : visibleTiles) {
            hexagon(civKnownMaskG, tileToClear.getX(), tileToClear.getY(), false);
        }
        civKnownMaskG.endDraw();
        
        renderVisibleCityMarkers(visibleTiles);
    }

    public void maskUnknown() {
        knownDarkG.beginDraw();
        knownDarkG.background(#000032);
        knownDarkG.endDraw();
        knownDarkG.mask(civKnownMaskG);
    }
    
    public void renderHUD() {
        int drawX = 20;
        civHUDG.beginDraw();
        //civHUDG.textFont(font);
        civHUDG.textSize(17);
        civHUDG.image(scienceImg, drawX, 20, 20, 20);
        civHUDG.text("+"+String.format("%,d", sciencePT), drawX+25, 35);
        drawX += Integer.toString(sciencePT).length()*20;
        civHUDG.image(cultureImg, drawX, 20, 20, 20);
        civHUDG.text("+"+String.format("%,d", culturePT), drawX+25, 35);
        drawX += Integer.toString(culturePT).length()*20 + 30;
        civHUDG.image(goldImg, drawX, 20, 20, 20);
        civHUDG.text(String.format("%,d", gold)+" (+"+String.format("%,d", goldPT)+")", drawX+25, 35);
        drawX += (Integer.toString(gold).length() + Integer.toString(goldPT).length())*20 + 30;
        if (happiness >= 0) {
            civHUDG.image(happiness_happyImg, drawX, 20, 20, 20);
        } else if (happiness > -10) {
            civHUDG.image(happiness_unhappyImg, drawX, 20, 20, 20);
        } else {
            civHUDG.image(happiness_lividImg, drawX, 20, 20, 20);
        }
        civHUDG.text(happiness, drawX+25, 35);
        civHUDG.endDraw();
    }
    
    public void hideHUD() {
        civHUDG.beginDraw();
        civHUDG.clear();
        civHUDG.endDraw();
    }  

    public void updateHUD() {
        hideHUD();
        renderHUD();
    }
    
    public void snapToUnit() {
        snapCamera(lastInteractedPos.x, lastInteractedPos.y);
    }

    public void setlastInteractedPos(float _x, float _y) {
        lastInteractedPos = new PVector(_x, _y);
    }
    
    public int getCityCount() {
        return cities.size();
    }
    
    public void addKnownCity(City city) {
        knownCities.add(city);
    }

    public Set<Civ> atWarWith() {
        Set<Civ> atWar = new HashSet<Civ>();
        for (Civ civ : knownCivs.keySet()) {
            if (knownCivs.get(civ) == RelationshipState.WAR) {
                atWar.add(civ);
            }
        }
        return atWar;
    }
    
    public void addUnit(AxialCoord coord, Unit unit) {
        addToMapStack(civUnitMap, coord, unit);
        int size = secondaryUnitHitboxes.containsKey(coord) ? secondaryUnitHitboxes.get(coord).size() : 0;
        addToMapStack(secondaryUnitHitboxes, coord, new PVector(unit.getX()+(hexRadius/2)-(hexRadius/2)*size, unit.getY()));
    }

    public void bringUnitToFront(AxialCoord coord, int index) {
        Stack<Unit> tempStack = board.getUnitsAtCoord(coord);
        Unit tempUnit = tempStack.get(index);
        if (tempUnit != board.getFrontUnitAtCoord(coord)) {
            tempStack.remove(index);
            tempStack.insertElementAt(tempUnit, tempStack.size());
            board.setUnitsAtCoord(coord, tempStack);

            tempUnit.clearPosition();
            tempUnit.render();
        }
    }

    public boolean isSecondaryUnitAtCoord(AxialCoord coord) {
        return secondaryUnitHitboxes.containsKey(coord);
    }

    public Stack<PVector> getSecondaryUnitHitboxes(AxialCoord coord) {
        return secondaryUnitHitboxes.get(coord);
    }
    
    public void removeUnit(AxialCoord coord) {
        popFromStack(civUnitMap, coord);
        popFromStack(secondaryUnitHitboxes, coord);
    }

    public void recheckBombard() {
        for (City city : cities) {
            city.checkBombard();
        }
    }
    
    public void addCity() {
        boolean isolatedEnough = true;
        for (AxialCoord coord : board.getCityMapCoords()) {
            if (coord.dist(selectedUnit.getHex()) < 4) {
                isolatedEnough = false;
                break;
            }
        }
        if (isolatedEnough) {
            City city = new City(cityNames[cities.size()], this, selectedUnit.getTile());
            board.addCity(selectedUnit.getHex(), city);
            board.addCityTileCoords(city.getTileCoords());
            cities.add(city);
            knownCities.add(city);
            selectedUnit.delete();
        } else {
            print("Error! Too close!");
        }
    }

    public void annexCity(City city) {
        cities.add(city);
    }

    public void removeCity(City city) {
        cities.remove(city);
    }

    @Override
    public String toString() {
        return type.toString();
    }
}

public enum CivName {
    CHINA(new String[]{"Beijing", "Guangzhou", "Shanghai", "Hong Kong", "Shenzhen", 
                       "Xi'an", "Chengdu", "Chongqing", "Nanjing", "Hangzhou", 
                       "Suzhou", "Changsha", "Zhengzhou", "Wuhan", "Tianjin", 
                       "Shenyang", "Qingdao", "Dalian", "Ningbo", "Dongguan"}, #EE1C25, #FFFF00),
    AMERICA(new String[]{"Jamestown", "Boston", "New York City", "Philadelphia", "Charleston",
                         "Richmond", "Baltimore", "Washington, D.C.", "New Orleans", "St. Louis",
                         "Chicago", "San Francisco", "Denver", "Atlanta", "Seattle",
                         "Detroit", "Los Angeles", "Miami", "Houston", "Dallas"}, #B31942, #0A3161),
    FRANCE(new String[]{"Paris", "Marseille", "Lyon", "Toulouse", "Nice",
                        "Nantes", "Strasbourg", "Montpellier", "Bordeaux", "Lille",
                        "Rennes", "Reims", "Saint-Étienne", "Toulon", "Le Havre",
                        "Grenoble", "Dijon", "Angers", "Nîmes", "Villeurbanne"}, #0055A4, #EF4135);
    
    private String[] cityNames;
    private color primaryColor;
    private color secondaryColor;
    private PImage icon;
    
    CivName(String[] _cityNames, color _primaryColor, color _secondaryColor) {
        cityNames = _cityNames;
        primaryColor = _primaryColor;
        secondaryColor = _secondaryColor;
    }
    
    public String[] getCityNames() {return cityNames;}
    public color getPrimaryColor() {return primaryColor;}
    public color getSecondaryColor() {return secondaryColor;}
    
    public void setIcon(PImage _icon) {icon = _icon;}
    
    public PImage getIcon() {return icon;}
}

public enum RelationshipState {
    NEUTRAL, FRIENDLY, GUARDED, HOSTILE, AFRAID, DENOUNCING, WAR, ALLY;

    public boolean isFriendly() {
        return this == NEUTRAL || this == FRIENDLY || this == ALLY;
    }
}