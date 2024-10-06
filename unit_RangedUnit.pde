class RangedUnit extends AttackingUnit {
    private Set<AxialCoord> attackCoords = new HashSet<>();

    public RangedUnit(int _q, int _r, float _x, float _y, UnitType _type, Civ _civ, City _city) {
        super(_q, _r, _x, _y, _type, _civ, _city);
    }

    public void attack(Unit enemy) {
        if (hasAttacked == false && isLand == type.isLand()) {
            moves--;
            if (moves == 0) {
                enemies = new HashSet<>();
            }
            enemy.takeDamage(this);
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
            enemyCity.takeDamage(this);
            deselect();
            hasAttacked = true;
        } else {
            enemies = new HashSet<>();
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
        if (!enemies.isEmpty()) {
            Boundary attackBoundary = new Boundary(attackCoords);
            attackBoundary.renderOuter(highlightG, #FF0000);
        }
        if (!embarkCoords.isEmpty()) {
            Boundary embarkBoundary = new Boundary(embarkCoords);
            embarkBoundary.renderInner(highlightG, #00008B);
        }
        selectedUnit = this;
        civ.setlastInteractedPos(x, y);
        validMoves = validTileCoords;
    }

    public void deselect() {
        attackCoords = new HashSet<>();
        super.deselect();
    }

    public void findRangedEnemies() {
        Queue<AxialCoord> queue = new LinkedList<>();
        HashMap<AxialCoord, Integer> visitedCost = new HashMap<>();

        AxialCoord startHex = new AxialCoord(q, r);
        queue.add(startHex);
        visitedCost.put(startHex, 0);
        while (!queue.isEmpty()) {
            AxialCoord current = queue.remove();
            int currentCost = visitedCost.get(current);
            List<Tile> neighbours = board.getNeighbours(current.getQ(), current.getR());

            for (Tile neighbour : neighbours) {
                int newCost = currentCost + 1;
                AxialCoord neighbourHex = neighbour.getHex();
                if (newCost <= visibilityBudget && !visitedCost.containsKey(neighbourHex)) {
                    visitedCost.put(neighbourHex, newCost);
                    if (!neighbour.getType().isRangedOccluder()) {
                        queue.add(neighbourHex);
                    }
                    City targetCity = board.getCityAtCoord(neighbourHex);
                    if (targetCity != null && civ.getRelationship(targetCity.getCiv()) == RelationshipState.WAR) {
                        enemyCities.add(targetCity);
                    }
                    if (board.getUnitMapCoords().contains(neighbourHex)) {
                        Unit targetUnit = board.getFrontUnitAtCoord(neighbourHex);
                        if (civ.getRelationship(targetUnit.getCiv()) == RelationshipState.WAR) {
                            enemies.add(targetUnit);
                        }
                    }
                    attackCoords.add(neighbourHex);
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
            findRangedEnemies();
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