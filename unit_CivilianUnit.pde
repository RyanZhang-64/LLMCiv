class CivilianUnit extends Unit {
    public CivilianUnit(int _q, int _r, float _x, float _y, UnitType _type, Civ _civ, City _city) {
        super(_q, _r, _x, _y, _type, _civ, _city);
    }

    private int getCombatStrength() {
        if (city != null) {
            return city.getModifiedCombatStrength(type);
        } else {
            return type.getCombatStrength();
        }
    }
    
    public boolean takeDamage(AttackingUnit enemy) {
        if (enemy instanceof RangedUnit) {
            hp -= (int) (30*exp(0.04*(enemy.getCombatStrength()-this.getCombatStrength()))*random(0.8,1.2));
            if (hp > 0) {
                updateHealthBar();
                return false;
            } else {
                enemy.getCiv().recheckBombard();
                delete();
                return true;
            }
        } else {
            enemy.getCiv().recheckBombard();
            delete();
            civ = enemy.getCiv();
            city = null;
            thisCiv.addUnit(getHex(), this);
            board.addUnit(getHex(), this);
            updateColor();
            render();
            return true;
        }
    }

    public boolean takeDamage (City enemyCity) {
        hp -= (int) (30*exp(0.04*(enemyCity.getCombatStrength()-this.getCombatStrength()))*random(0.8,1.2));
        if (hp > 0) {
            updateHealthBar();
            return false;
        } else {
            delete();
            return true;
        }
    }

    public void improveTile(ImprovementType improvementType) {
        Tile tile = board.getTileAtCoord(getHex());
        if (civ.isTileInCiv(tile)) {
            switch (improvementType) {
                case FARM:
                    if (tile.isArable()) {
                        tile.setImprovement(ImprovementType.FARM, civ.getCityOfCoord(getHex()));
                        selectedUnit.delete();
                    }
                    break;
                default:
                    break;
            }
        }
    }

    public void select() {
        if (type != UnitType.TRADER) {
            HashMap<AxialCoord, Integer> validTileCoords = bfs(true);
            Boundary boundary = new Boundary(validTileCoords.keySet());
            boundary.render(highlightG, #009FC7, #02CCFE, true);
            
            if (type == UnitType.SETTLER) {
                gui.show(GUIType.SETTLE, true);
            } else if (type == UnitType.WORKER) {
                Tile tile = board.getTileAtCoord(getHex());
                gui.show(GUIType.FARM, civ.isTileInCiv(tile) && tile.isArable());
            }
            if (!embarkCoords.isEmpty()) {
                Boundary embarkBoundary = new Boundary(embarkCoords);
                embarkBoundary.renderInner(highlightG, #00008B);
            }
            validMoves = validTileCoords;
        } else if (civ.isTileCity(getHex()) != null) {
            Set<City> cities = civ.getFriendlyCities();
            ArrayList<Option> validCities = new ArrayList<>();
            for (City city : cities) {
                if (getHex().dist(city.getHex()) < 20) {
                    validCities.add(new Option(city.getName(), city));
                }
            }
            productionMenu = new ProductionMenu(validCities, 50, 50, 200, 200, 0);
            board.setState(State.TRADER);
            productionMenu.drawOptions();
        }
        selectedUnit = this;
        civ.setlastInteractedPos(x, y);
    }

    public void deselect() {
        selectedUnit = null;
        validMoves = new HashMap<>();
        embarkCoords = new HashSet<>();
        highlightG.beginDraw();
        highlightG.clear();
        highlightG.endDraw();
        
        if (type == UnitType.SETTLER) {
            gui.hide(GUIType.SETTLE);
        } else if (type == UnitType.WORKER) {
            gui.hide(GUIType.FARM);
        } else if (type == UnitType.TRADER) {
            menuG.beginDraw();
            menuG.clear();
            menuG.endDraw();
            productionMenu = null;
            board.setState(State.GAME);
        }
    }

    private YieldType carrying = null;
    private int quantity = 0;

    public void trade(City tradeCity) {
        carrying = YieldType.FOOD;
        quantity = 10;
        board.addUnitToMultiMove(this, tradeCity.getHex());
        multiMove(tradeCity.getHex());
    }

    public YieldType getCarrying() {return carrying;}
    public int getQuantity() {return quantity;}

    public HashMap<AxialCoord, Integer> bfs(boolean isTravel) {
        Queue<AxialCoord> queue = new LinkedList<>();
        HashMap<AxialCoord, Integer> visitedCost = new HashMap<>();
        AxialCoord startHex = new AxialCoord(q, r);
        queue.add(startHex);
        visitedCost.put(startHex, 0);
    
        BfsStrategy strategy;
        if (isTravel) {
            strategy = new PassiveTravelStrategy(this);
        } else {
            strategy = new VisibilityStrategy(this);
        }
    
        while (!queue.isEmpty()) {
            AxialCoord current = queue.remove();
            int currentCost = visitedCost.get(current);
            strategy.processNode(current, currentCost, queue, visitedCost);
        }
    
        return visitedCost;
    }
}