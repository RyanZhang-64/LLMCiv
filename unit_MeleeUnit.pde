class MeleeTravelStrategy implements BfsStrategy {
    private MeleeUnit unit;

    MeleeTravelStrategy(MeleeUnit _unit) {
        this.unit = _unit;
    }

    @Override
    public void processNode(AxialCoord current, int currentCost, Queue<AxialCoord> queue, HashMap<AxialCoord, Integer> visitedCost) {
        List<Tile> neighbours = board.getNeighbours(current.getQ(), current.getR());
        for (Tile neighbour : neighbours) {
            int newCost = currentCost + (unit.isLand() ? neighbour.type.getTravelCost() : neighbour.type.getSeaTravelCost());
            AxialCoord neighbourHex = neighbour.getHex();
            if (!visitedCost.containsKey(neighbourHex)) {
                if (newCost <= unit.moves) {
                    City targetCity = board.getCityAtCoord(neighbourHex);
                    if (!board.getUnitMapCoords().contains(neighbourHex) && (targetCity == null || unit.civ.getRelationship(targetCity.getCiv()).isFriendly())) {
                        queue.add(neighbourHex);
                        visitedCost.put(neighbourHex, newCost);
                    } else if (!unit.hasAttacked) {
                        Unit targetUnit = board.getFrontUnitAtCoord(neighbourHex);
                        if (targetUnit != null && unit.civ.getRelationship(targetUnit.getCiv()) == RelationshipState.WAR) {
                            enemies.add(targetUnit);
                        }
                        if (targetCity != null && unit.civ.getRelationship(targetCity.getCiv()) == RelationshipState.WAR) {
                            enemyCities.add(targetCity);
                        }
                    }
                } else if ((unit.isLand() == neighbour.getType().isWater()) && !board.getUnitMapCoords().contains(neighbourHex) && unit.moves-currentCost >= 1) {
                    embarkCoords.add(neighbourHex);
                }
            }
        }
    }
}

class MeleeUnit extends AttackingUnit {
    private boolean isAutomated;
    
    public MeleeUnit(int _q, int _r, float _x, float _y, UnitType _type, Civ _civ, City _city) {
        super(_q, _r, _x, _y, _type, _civ, _city);
    }
    
    public void attack(Unit enemy) {
        if (hasAttacked == false && isLand == type.isLand()) {
            moves--;
            if (moves == 0) {
                enemies = new HashSet<>();
            }
            if (getHex().dist(enemy.getHex()) != 1) {
                approach(enemy.getHex());
            }
            if (!enemy.takeDamage(this)) {
                takeDamage((AttackingUnit) enemy);
            } else {
                move(enemy.getHex(), 0);
            }
            deselect();
            hasAttacked = true;
        } else {
            enemies = new HashSet<>();
        }
    }

    public void siege(City enemyCity) {
        if (hasAttacked == false && isLand == type.isLand()) {
            moves--;
            if (moves == 0) {
                enemies = new HashSet<>();
            }
            if (getHex().dist(enemyCity.getHex()) != 1) {
                approach(enemyCity.getHex());
            }
            if (!enemyCity.takeDamage(this)) {
                takeDamage((City) enemyCity);
            } else {
                move(enemyCity.getHex(), 0);
            }
            deselect();
            hasAttacked = true;
        } else {
            enemies = new HashSet<>();
        }
    }

    public boolean isAutomated() {return isAutomated;}
    public void setAutomated(boolean automated) {isAutomated = automated;}

    public void automate() {
        HashMap<AxialCoord, Integer> moves = validMoves;
        if (moves.isEmpty()) {
            moves = bfs(true);
        }
        int mostUncovered = 0;
        AxialCoord mostUncoveredCoord = null;
        int mostUncoveredCost = 0;
        for (Map.Entry<AxialCoord, Integer> entry : moves.entrySet()) {
            Set<AxialCoord> newHexes = board.getCoordsWithinRange(entry.getKey(), 2);
            int uncovers = 0;
            for (AxialCoord newHex : newHexes) {
                if (!civ.getVisibleTiles().contains(board.getTileAtCoord(newHex))) {
                    uncovers++;
                }
            }
            if (uncovers > mostUncovered) {
                mostUncovered = uncovers;
                mostUncoveredCoord = entry.getKey();
                mostUncoveredCost = entry.getValue();
            }
        }
        println(mostUncoveredCoord == null || mostUncoveredCoord.equals(getHex()));
        if (mostUncoveredCoord == null || mostUncoveredCoord.equals(getHex())) {
            AxialCoord nearestFog = getNearestFog();
            multiMove(nearestFog);
            board.addUnitToMultiMove(this, nearestFog);
            board.removeUnitToAutomate(this);
        } else {
            if (embarkCoords.contains(mostUncoveredCoord)) {
                embark(mostUncoveredCoord);
            } else {
                move(mostUncoveredCoord, mostUncoveredCost);
            }
        }
    }

    public void select() {
        HashMap<AxialCoord, Integer> validTileCoords = bfs(true);
        Boundary boundary = new Boundary(validTileCoords.keySet());
        boundary.render(highlightG, #009FC7, #02CCFE, true);
        
        if (board.isUnitMultiMove(this)) {
            enemies = new HashSet<>();
            enemyCities = new HashSet<>();
        }
        for (Unit enemy : enemies) {
            Boundary enemyHighlight = new Boundary(Set.of(enemy.getHex()));
            enemyHighlight.renderInner(highlightG, #FF0000);
        }
        for (City enemyCity : enemyCities) {
            Boundary cityHighlight = new Boundary(Set.of(enemyCity.getHex()));
            cityHighlight.renderInner(highlightG, #FF0000);
        }
        for (AxialCoord coord : embarkCoords) {
            Boundary embarkBoundary = new Boundary(Set.of(coord));
            embarkBoundary.renderInner(highlightG, #4e4ed4);
        }
        if (type == UnitType.SCOUT) {
            gui.show(GUIType.AUTOMATE, true);
        }
        isAutomated = false;
        board.removeUnitToAutomate(this);
        selectedUnit = this;
        civ.setlastInteractedPos(x, y);
        validMoves = validTileCoords;
    }

    public void approach(AxialCoord enemyCoord) {
        Queue<AxialCoord> queue = new LinkedList<>();
        HashMap<AxialCoord, Integer> visitedCost = new HashMap<>();
        HashSet<AxialCoord> unitCoords = new HashSet<>();
        
        AxialCoord startHex = new AxialCoord(q, r);
        queue.add(startHex);
        visitedCost.put(startHex, 0);
        
        for (Unit unit : board.getUnitMapUnits()) {
            unitCoords.add(unit.getHex());
        }
        
        while (!queue.isEmpty()) {
            AxialCoord current = queue.remove();
            int currentCost = visitedCost.get(current);
            List<Tile> neighbours = board.getNeighbours(current.getQ(), current.getR());
            
            for (Tile neighbour : neighbours) {
                int newCost = currentCost + (getType().isLand() ? neighbour.type.getTravelCost() : neighbour.type.getSeaTravelCost());
                AxialCoord neighbourHex = neighbour.getHex();
                
                if (newCost <= moves && !visitedCost.containsKey(neighbourHex) && !unitCoords.contains(neighbourHex)) {
                    
                    // Check if this tile is adjacent to the enemy's position
                    if (neighbourHex.dist(enemyCoord) == 1) {
                        this.move(neighbourHex, newCost);
                    }
                    queue.add(neighbourHex);
                    visitedCost.put(neighbourHex, newCost);
                }
            }
        }
    }

    @Override
    public boolean takeDamage(AttackingUnit enemy) {
        return super.takeDamage(enemy);
    }

    public HashMap<AxialCoord, Integer> bfs(boolean isTravel) {
        Queue<AxialCoord> queue = new LinkedList<>();
        HashMap<AxialCoord, Integer> visitedCost = new HashMap<>();
        AxialCoord startHex = new AxialCoord(q, r);
        queue.add(startHex);
        visitedCost.put(startHex, 0);
    
        BfsStrategy strategy;
        if (isTravel) {
            strategy = new MeleeTravelStrategy(this);
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