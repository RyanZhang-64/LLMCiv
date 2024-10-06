abstract class AttackingUnit extends Unit {
    public AttackingUnit(int _q, int _r, float _x, float _y, UnitType _type, Civ _civ, City _city) {
        super(_q, _r, _x, _y, _type, _civ, _city);
    }
    
    public int getCombatStrength() {
        if (city != null) {
            return city.getModifiedCombatStrength(type);
        } else {
            return type.getCombatStrength();
        }
    }

    public boolean takeDamage(AttackingUnit enemy) {
        hp -= (int) (30*exp(0.04*(enemy.getCombatStrength()-this.getCombatStrength()))*random(0.8,1.2));
        if (hp > 0) {
            updateHealthBar();
            return false;
        } else {
            enemy.getCiv().recheckBombard();
            delete();
            return true;
        }
    }

     public boolean takeDamage(City enemyCity) {
        hp -= (int) (30*exp(0.04*(enemyCity.getCombatStrength()-this.getCombatStrength()))*random(0.8,1.2));
        if (hp > 0) {
            updateHealthBar();
            return false;
        } else {
            delete();
            return true;
        }
    }

    public void deselect() {
        selectedUnit = null;
        validMoves = new HashMap<>();
        enemies = new HashSet<>();
        enemyCities = new HashSet<>();
        embarkCoords = new HashSet<>();
        highlightG.beginDraw();
        highlightG.clear();
        highlightG.endDraw();

        if (type == UnitType.SCOUT) {
            gui.hide(GUIType.AUTOMATE);
        }
    }
}