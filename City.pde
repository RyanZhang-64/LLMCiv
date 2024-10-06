public class City {
    private String name;
    private Civ civ;
    private AxialCoord centerCoord;
    private float x, y;
    private int population;
    private float foodBasket;
    private int turnsSincePopulationGrowth;
    
    private float cityCombatModifier;
     
    private HashMap<AxialCoord, Tile> tiles;
    private ArrayList<Option> productionOptions;
    
    private boolean isMarkerOffset;
    private boolean hasBombarded;
    private boolean isBombarding;
    
    private UnitType producing;
    private int turnsToProduce;

    private boolean isCoastal;

    private int foodPT;
    private int productionPT;
    private int goldPT;

    private int hp;
    private int combatStrength;
    private int defense;
    
    void star(float x, float y, float size, PGraphics pg) {
        float radius1 = size / 2;  // Outer radius
        float radius2 = radius1 * 0.382;  // Inner radius (about 38.2% of the outer radius, typical for a star)
        float angle = TWO_PI / 5;  // Angle between points of the star
    
        pg.beginShape();
        for (int i = 0; i < 10; i++) {
            float r = (i % 2 == 0) ? radius1 : radius2;
            float px = x + cos(i * angle + PI/2) * r;  // PI/2 to rotate the star to point upwards
            float py = y - sin(i * angle + PI/2) * r;
            pg.vertex(px, py);
        }
        pg.endShape(CLOSE);  // Close the shape
    }
    
    public City(String _name, Civ _civ, Tile _tile) {
        name = _name;
        civ = _civ;
        centerCoord = _tile.getHex();
        x = _tile.getX();
        y = _tile.getY();
        population = 0;
        
        producing = UnitType.NONE;
        turnsToProduce = -1;
        
        isMarkerOffset = false;
        hasBombarded = false;
        isBombarding = false;
       
        productionOptions = new ArrayList<Option>();
        tiles = new HashMap<AxialCoord, Tile>();
        foodPT = 0;
        turnsSincePopulationGrowth = 0;
        cityCombatModifier = 1;
        isCoastal = false;
        for (AxialCoord dir : directions) {
            int newQ = centerCoord.getQ() + dir.getQ();
            int newR = centerCoord.getR() + dir.getR();
            if (board.isWithinBounds(newQ, newR)) {
                Tile tile = board.getTileFromCoords(newQ, newR);
                if (tile.getType() == TileType.LAKE || tile.getType() == TileType.OCEAN) {
                    isCoastal = true;
                    break;
                }
            }
        }

        hp = 100;
        combatStrength = 3;
        defense = 1;
        
        Tile tile = board.getTileFromCoords(centerCoord.getQ(), centerCoord.getR());
        tiles.put(centerCoord, tile);
        foodPT += tile.getType().getFoodYield();
        
        for (AxialCoord dir : directions) {
            int newQ = centerCoord.getQ() + dir.getQ();
            int newR = centerCoord.getR() + dir.getR();
            if (board.isWithinBounds(newQ, newR)) {
                Tile tileInBound = board.getTileFromCoords(newQ, newR);
                tiles.put(new AxialCoord(newQ, newR), tileInBound);
                foodPT += tileInBound.getType().getFoodYield();
                ResourceType resource = tileInBound.getResource();
                if (resource != null) {
                    switch (resource.getYieldType()) {
                        case FOOD:
                            foodPT += resource.getYield();
                            civ.addFoodPT(resource.getYield());
                            break;
                        case PRODUCTION:
                            productionPT += resource.getYield();
                            civ.addProductionPT(resource.getYield());
                            break;
                        case GOLD:
                            goldPT += resource.getYield();
                            civ.addGoldPT(resource.getYield());
                            break;
                        default:
                            break;
                    }
                }
            }
        }
        
        civ.addVisibleTiles(new HashSet<>(tiles.values()));
        civ.addTiles(new HashSet<>(tiles.values()));
        
        Boundary boundary = new Boundary(tiles.keySet());
        boundary.render(cityBoundariesG, civ.getPrimaryColor(), civ.getSecondaryColor(), false);
        
        tile.makeCityCenter();
        
        if (civ.getCityCount() == 0) {
            civ.setCapital(this);
        }
        drawRectAndTitle(civ.civCityMarkerG);
        drawPopulationTurnsAndPopulationDisplay(civ.civCityMarkerG);
        drawProductionTurnsAndIconDisplay(civ.civCityMarkerG);
        
        drawMask();
    }
    
    public String getName() {return name;}
    public Civ getCiv() {return civ;}
    public AxialCoord getHex() {return centerCoord;}
    public Set<AxialCoord> getTileCoords() {return tiles.keySet();}
    public float getX() {return x;}
    public float getY() {return y;}
    public int getPopulation() {return population;}
    public ArrayList<Option> getProductionOptions() {return productionOptions;}
    public boolean isMarkerOffset() {return isMarkerOffset;}

    public int getCombatStrength() {return getModifiedCityCombatStrength();}
    public int getModifiedCityCombatStrength() {return (int) (combatStrength * cityCombatModifier);}
    
    public void setMarkerOffset(boolean bool) {
        isMarkerOffset = bool;
        update(civ.civCityMarkerG);
    }

    public void update(PGraphics pg) {
        clearRectAndTitle(civ.civCityMarkerG);
        drawRectAndTitle(civ.civCityMarkerG);
        drawPopulationTurnsAndPopulationDisplay(civ.civCityMarkerG);
        drawProductionTurnsAndIconDisplay(civ.civCityMarkerG);
        updateHealthBar(civ.civCityMarkerG);
        updateHealthBar(pg);
    }
    
    public void addFoodPT(int increase) {
        foodPT += increase;
        clearPopulationTurnsAndPopulationDisplay(civ.civCityMarkerG);
        drawPopulationTurnsAndPopulationDisplay(civ.civCityMarkerG);
    }
    
    public void drawMask() {
        cityMaskG.beginDraw();
        cityMaskG.clear();
        cityMaskG.translate(negOffsetX, negOffsetY);
        cityMaskG.background(200);
        cityMaskG.fill(0);
        cityMaskG.noStroke();
        for (Tile tileToClear : tiles.values()) {
            hexagon(cityMaskG, tileToClear.getX(), tileToClear.getY(), true);
        }
        cityMaskG.endDraw();
    }
     
    public void addProduction(UnitType unitType, int turns) {
        producing = unitType;
        turnsToProduce = turns;
        
        clearProductionTurnsAndIconDisplay(civ.civCityMarkerG);
        drawProductionTurnsAndIconDisplay(civ.civCityMarkerG);
    }

    public void drawBombardIcon() {
        civ.civCityMarkerG.beginDraw();
        civ.civCityMarkerG.translate(negOffsetX, negOffsetY);
        civ.civCityMarkerG.blendMode(BLEND);
        civ.civCityMarkerG.image(red_targetImg, x-15, y+3*hexRadius/2-15, 30, 30);
        civ.civCityMarkerG.endDraw();
    }

    public void clearBombardIcon() {
        civ.civCityMarkerG.beginDraw();
        civ.civCityMarkerG.translate(negOffsetX, negOffsetY);
        civ.civCityMarkerG.blendMode(REPLACE);
        civ.civCityMarkerG.noStroke();
        civ.civCityMarkerG.fill(0, 0);
        civ.civCityMarkerG.rect(x-15, y+3*hexRadius/2-15, 30, 30);
        civ.civCityMarkerG.endDraw();
    }

    public void showBombard() {
        snapCamera(x, y);
        selectedCity = this;
        isBombarding = true;
        for (Unit enemy : enemies) {
            Boundary enemyHighlight = new Boundary(Set.of(enemy.getHex()));
            enemyHighlight.renderInner(highlightG, #FF0000);
        }
    }

    public void checkBombard() {
        hasBombarded = false;

        Queue<AxialCoord> queue = new LinkedList<>();
        HashMap<AxialCoord, Integer> visitedCost = new HashMap<>();

        queue.add(centerCoord);
        visitedCost.put(centerCoord, 0);
        while (!queue.isEmpty()) {
            AxialCoord current = queue.remove();
            int currentCost = visitedCost.get(current);
            List<Tile> neighbours = board.getNeighbours(current.getQ(), current.getR());

            for (Tile neighbour : neighbours) {
                int newCost = currentCost + 1;
                AxialCoord neighbourHex = neighbour.getHex();
                if (newCost <= 2 && !visitedCost.containsKey(neighbourHex)) {
                    visitedCost.put(neighbourHex, newCost);
                    if (!neighbour.getType().isRangedOccluder()) {
                        queue.add(neighbourHex);
                    }
                    if (board.getUnitMapCoords().contains(neighbourHex)) {
                        Unit targetUnit = board.getFrontUnitAtCoord(neighbourHex);
                        if (civ.getRelationship(targetUnit.getCiv()) == RelationshipState.WAR) {
                            enemies.add(targetUnit);
                        }
                    }
                }
            }
        }

        if (!enemies.isEmpty() && hasBombarded == false) {
            drawBombardIcon();
            civ.addCityBombardHitbox(new PVector(x, y+3*hexRadius/2), this);
        } else {
            clearBombardIcon();
            civ.removeCityBombardHitbox(new PVector(x, y+3*hexRadius/2));
        }
    }

    public void bombard(Unit enemy) {
        enemy.takeDamage(this);
        hasBombarded = true;
        clearBombardIcon();
        civ.removeCityBombardHitbox(new PVector(x, y+3*hexRadius/2));
        cancelBombard();
    }

    public void cancelBombard() {
        isBombarding = false;
        selectedCity = null;
        highlightG.beginDraw();
        highlightG.clear();
        highlightG.endDraw();
    }

    public boolean isBombarding() {
        return isBombarding;
    }

    public boolean hasBombarded() {
        return hasBombarded;
    }
    
    public int getModifiedCombatStrength(UnitType type) {
        return (int) (type.getCombatStrength() * cityCombatModifier);
    }
    
    public void decrementTurnsToProduce() {
        if (turnsToProduce != -1) {
            if (turnsToProduce == 1) {
                Unit newUnit = board.createUnit(centerCoord.getQ(), centerCoord.getR(), x, y, producing, civ, this);
                if (board.isUnitAtCoord(centerCoord)) {
                    board.getFrontUnitAtCoord(centerCoord).clearPosition();
                }
                thisCiv.addUnit(centerCoord, newUnit);
                board.addUnit(centerCoord, newUnit);
                newUnit.render();
                
                producing = UnitType.NONE;
                turnsToProduce = -1;
                clearProductionTurnsAndIconDisplay(civ.civCityMarkerG);
                drawProductionTurnsAndIconDisplay(civ.civCityMarkerG);
            } else {
                turnsToProduce--;
                updateProductionTurnsDisplay(civ.civCityMarkerG);
            }
        }
    }
    
    public void applyPT() {
        foodBasket += foodPT - population;
        turnsSincePopulationGrowth++;
        float foodBasketThreshold = 15+8*(population-1)+pow((population-1), 2);
        if (foodBasket > foodBasketThreshold) {
            foodBasket -= foodBasketThreshold;
            population++;
            turnsSincePopulationGrowth = 0;
        }
        clearPopulationTurnsAndPopulationDisplay(civ.civCityMarkerG);
        drawPopulationTurnsAndPopulationDisplay(civ.civCityMarkerG);
    }
    
    public int estimatedTurnsToNextPopulation() {
        if (foodPT-population == 0) {
            return -1;
        } else {
            return (int) Math.ceil((15+8*(population-1)+pow((population-1), 2)) / (foodPT-population)) - turnsSincePopulationGrowth;
        }
    }

    public void dropOffTrade(YieldType yield, int quantity) {
        switch (yield) {
            case FOOD:
                foodBasket += quantity;
                break;
            default:
                break;
        }
    }
    
    // Should change dynamically
    public void updateProductionOptions() {
        ArrayList<Option> newProductionOptions = new ArrayList<Option>();
        newProductionOptions.add(new Option("Units")); // Category toggler
        newProductionOptions.add(new Option("Settler", UnitType.SETTLER));
        newProductionOptions.add(new Option("Worker", UnitType.WORKER));
        newProductionOptions.add(new Option("Scout", UnitType.SCOUT));
        newProductionOptions.add(new Option("Archer", UnitType.ARCHER));
        newProductionOptions.add(new Option("Trader", UnitType.TRADER));
        if (isCoastal) {
            newProductionOptions.add(new Option("Galley", UnitType.GALLEY));
            newProductionOptions.add(new Option("Quad", UnitType.QUAD));
        }
        productionOptions = newProductionOptions;
    }
    
    public int getProductionIndex(Option option) {
        return productionOptions.indexOf(option);
    }
    
    public int getProductionOptionsCount() {
        return productionOptions.size();
    }
    
    public boolean isProductionOptionCategory(int index) {
        return productionOptions.get(index).isCategory();
    }
    
    public ArrayList<Tile> getTiles() {
        return new ArrayList<>(tiles.values());
    }
    
    public boolean equals(City city) {
        return this.name == city.getName();
    }
    
    public boolean isUnitAtCityCenter() {
        return board.isUnitAtCoord(centerCoord);
    }

    public boolean takeDamage(AttackingUnit enemy) {
        hp -= (int) (30*exp(0.04*(enemy.getCombatStrength()-combatStrength))*random(0.8,1.2));
        if (hp > 0) {
            updateHealthBar(civ.civCityMarkerG);
            updateHealthBar(enemy.getCiv().civCityMarkerG);
            return false;
        } else {
            if (enemy instanceof MeleeUnit) {
                civ.removeCity(this);
                civ = enemy.getCiv();
                civ.annexCity(this);
                hp = 50;
                update(enemy.getCiv().civCityMarkerG);
                return true;
            } else {
                hp = 0;
                return false;
            }
        }
    }

    public void seeNew() {
        Set<AxialCoord> newCities = new HashSet<>(tiles.keySet());
        Set<AxialCoord> newUnits = new HashSet<>(board.getUnitMapCoords());
        newUnits.retainAll(tiles.keySet());
        newCities.retainAll(board.getCityMapCoords());
        for (AxialCoord coord : newUnits) {
            for (Unit unit : board.getUnitsAtCoord(coord)) {
                if (!civ.isCivKnown(unit.getCiv())) {
                    civ.addKnownCiv(unit.getCiv());
                }
            }
        }
    }

    public void heal() {
        if (hp < 100) {
            if (hp <= 90) {
                hp = 100;
            } else {
                hp += 10;
            }
            updateHealthBar(civ.civCityMarkerG);
            for (Civ tempCiv : civ.atWarWith()) {
                updateHealthBar(tempCiv.civCityMarkerG);
            }
        }
    }

    public void renderHealthBar(PGraphics pg) {
        if (hp < 100) {
            pg.fill(0);
            pg.rect(x-8*hexRadius/3, y-4*hexRadius/3 + (isMarkerOffset ? 0 : hexRadius), 16*hexRadius/3, 10); // Draw the black background
            pg.stroke(0);
            float healthWidth = map(hp, 0, 100, 0, 16*hexRadius/3);
            float hue = map(hp, 0, 100, 0, 120); // 120 is green, 0 is red in HSB
            pg.colorMode(HSB, 360, 100, 100);
            pg.fill(hue, 100, 100);
            pg.colorMode(RGB, 255, 255, 255);
            pg.rect(x-8*hexRadius/3, y-4*hexRadius/3 + (isMarkerOffset ? 0 : hexRadius), healthWidth, 10); // Draw the health bar that depletes
        }
    }
    
    public void updateHealthBar(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY);
        pg.blendMode(REPLACE);
        pg.noStroke();
        pg.fill(0,0);
        pg.rect(x-8*hexRadius/3-1, y-4*hexRadius/3-1 + (isMarkerOffset ? 0 : hexRadius), 16*hexRadius/3+2, 12); // Draw the black background
        pg.blendMode(BLEND);
        if (hp < 100) {
            renderHealthBar(pg);
        }
        pg.endDraw();
    }
    
    public void drawForeignCityMarker(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY);
        pg.blendMode(BLEND);
        pg.strokeWeight(2);
        pg.stroke(255);
        pg.fill(civ.getPrimaryColor());
        pg.rect(x-8*hexRadius/3, y-hexRadius + (isMarkerOffset ? 0 : hexRadius), 16*hexRadius/3, hexRadius, 90);
        pg.textFont(font);
        pg.textSize(16*hexRadius/30);
        pg.textAlign(CENTER);
        if (civ.getCapital() == this) {
            pg.fill(255);
            star(x-1.15*hexRadius, y-hexRadius/2 + (isMarkerOffset ? 0 : hexRadius), 10*hexRadius/30, pg);
            pg.fill(civ.getSecondaryColor());
            pg.text(name, x+hexRadius/5, y-12*hexRadius/30 + (isMarkerOffset ? 0 : hexRadius));
        } else {
            pg.fill(civ.getSecondaryColor());
            pg.text(name, x, y-12*hexRadius/30 + (isMarkerOffset ? 0 : hexRadius));
        }
        pg.textSize(18*hexRadius/30);
        pg.textAlign(LEFT);
        pg.fill(civ.getSecondaryColor());
        pg.text(population, x-7*hexRadius/3, y+2*hexRadius/3);
        pg.image(civ.getType().getIcon(), x+52*hexRadius/30, y+3*hexRadius/30, 25*hexRadius/30, 25*hexRadius/30);
        pg.endDraw();
    }
    
    public void drawRectAndTitle(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY);
        pg.blendMode(BLEND);
        pg.strokeWeight(2);
        pg.stroke(255);
        pg.fill(civ.getPrimaryColor());
        pg.rect(x-8*hexRadius/3, y-hexRadius + (isMarkerOffset ? 0 : hexRadius), 16*hexRadius/3, hexRadius, 90);
        pg.textFont(font);
        pg.textSize(16*hexRadius/30);
        pg.textAlign(CENTER);
        if (civ.getCapital() == this) {
            pg.fill(255);
            star(x-1.15*hexRadius, y-hexRadius/2 + (isMarkerOffset ? 0 : hexRadius), 10*hexRadius/30, pg);
            pg.fill(civ.getSecondaryColor());
            pg.text(name, x+hexRadius/5, y-12*hexRadius/30 + (isMarkerOffset ? 0 : hexRadius));
        } else {
            pg.fill(civ.getSecondaryColor());
            pg.text(name, x, y-12*hexRadius/30 + (isMarkerOffset ? 0 : hexRadius));
        }
        pg.endDraw();
    }
    
    public void clearRectAndTitle(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY);
        pg.blendMode(REPLACE);
        pg.noStroke();
        pg.fill(0,0);
        pg.rect(x-82*hexRadius/30, y-2*hexRadius/30 - (isMarkerOffset ? 0 : hexRadius), 164*hexRadius/30, 34*hexRadius/30, 90);
        pg.endDraw();
    }
    
    // Replace both each time since no memory overhead
    public void drawPopulationTurnsAndPopulationDisplay(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY + (isMarkerOffset ? -hexRadius : 0));
        pg.blendMode(BLEND);
        pg.textSize(18*hexRadius/30);
        pg.textAlign(LEFT);
        pg.fill(civ.getSecondaryColor());
        pg.text(population, x-7*hexRadius/3, y+2*hexRadius/3);
        int estimatedTurns = estimatedTurnsToNextPopulation();
        if (estimatedTurns == -1) {
            pg.textSize(2*hexRadius/3);
            pg.text("∞", x-55*hexRadius/30, y+hexRadius);
        } else {
            pg.textSize(12*hexRadius/30);
            pg.text(estimatedTurns, x-55*hexRadius/30, y+5*hexRadius/6);
        }
        pg.endDraw();
    }
    
    public void clearPopulationTurnsAndPopulationDisplay(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY + (isMarkerOffset ? -hexRadius : 0));
        pg.blendMode(REPLACE);
        pg.noStroke();
        pg.fill(civ.getPrimaryColor());
        pg.rect(x-7*hexRadius/3, y+2*hexRadius/30, hexRadius, 26*hexRadius/30);
        pg.endDraw();
    }
    
    public void drawProductionTurnsAndIconDisplay(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY + (isMarkerOffset ? -hexRadius : 0));
        pg.blendMode(BLEND);
        pg.image(producing.getImg(), x+52*hexRadius/30, y+3*hexRadius/30, 25*hexRadius/30, 25*hexRadius/30);
        pg.fill(civ.getSecondaryColor());
        pg.textAlign(LEFT);
        if (turnsToProduce == -1) {
            pg.textSize(2*hexRadius/3);
            pg.text("∞", x+43*hexRadius/30, y+30*hexRadius/30);
        } else {
            pg.textSize(12*hexRadius/30);
            pg.text(turnsToProduce, x+43*hexRadius/30, y+25*hexRadius/30);
        }
        pg.endDraw();
    }
    
    public void clearProductionTurnsAndIconDisplay(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY + (isMarkerOffset ? -hexRadius : 0));
        pg.blendMode(REPLACE);
        pg.noStroke();
        pg.fill(civ.getPrimaryColor());
        pg.rect(x+40*hexRadius/30, y+2*hexRadius/30, 38*hexRadius/30, 26*hexRadius/30, 90);
        pg.endDraw();
    }
    
    public void updateProductionTurnsDisplay(PGraphics pg) {
        pg.beginDraw();
        pg.translate(negOffsetX, negOffsetY + (isMarkerOffset ? -hexRadius : 0));
        pg.blendMode(REPLACE);
        pg.noStroke();
        pg.fill(civ.getPrimaryColor());
        pg.rect(x+40*hexRadius/30, y+2*hexRadius/30, hexRadius/2, 26*hexRadius/30, 90);
        
        pg.textSize(hexRadius/2);
        pg.fill(civ.getSecondaryColor());
        pg.textAlign(LEFT);
        pg.text(turnsToProduce, x+45*hexRadius/30, y+25*hexRadius/30);
        pg.endDraw();
    }
}
