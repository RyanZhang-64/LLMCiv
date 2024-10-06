public enum Tech {
    AGRICULTURE("Agriculture", 0, 4), 
    POTTERY("Pottery", 1, 1), 
    ANIMAL_HUSBANDRY("Animal Husbandry", 1, 4), 
    ARCHERY("Archery", 1, 6), 
    MINING("Mining", 1, 8),
    SAILING("Sailing", 2, 0),
    CALENDAR("Calendar", 2, 1),
    WRITING("Writing", 2, 2),
    TRAPPING("Trapping", 2, 3),
    THE_WHEEL("The Wheel", 2, 5),
    MASONRY("Masonry", 2, 8),
    BRONZE_WORKING("Bronze Working", 2, 9);
    
    private PImage img;
    private String name;
    private int col, row;
    private Tech[] dependentTechs;

    Tech(String _name, int _col, int _row) { 
        name = _name;
        col = _col;
        row = _row;
    }
    
    public PImage getImg() {println("Get image for " + name + img); return img;}
    public String getName() {return name;}
    public int getCol() {return col;}
    public int getRow() {return row;}
    public Tech[] getDependentTechs() {return dependentTechs;}
    
    public void setImg(PImage _img) {img = _img; println("Set image for " + name + img);}
    public void setDependentTechs(Tech[] _dependentTechs) {dependentTechs = _dependentTechs;}

    // Initialize dependencies in a static block
    static {
        AGRICULTURE.setDependentTechs(new Tech[]{POTTERY, ANIMAL_HUSBANDRY, ARCHERY, MINING});
        POTTERY.setDependentTechs(new Tech[]{SAILING, CALENDAR, WRITING});
        ANIMAL_HUSBANDRY.setDependentTechs(new Tech[]{TRAPPING, THE_WHEEL});
        ARCHERY.setDependentTechs(new Tech[]{});
        MINING.setDependentTechs(new Tech[]{MASONRY, BRONZE_WORKING});
        SAILING.setDependentTechs(new Tech[]{});
        CALENDAR.setDependentTechs(new Tech[]{});
        WRITING.setDependentTechs(new Tech[]{});
        TRAPPING.setDependentTechs(new Tech[]{});
        THE_WHEEL.setDependentTechs(new Tech[]{});
        MASONRY.setDependentTechs(new Tech[]{});
        BRONZE_WORKING.setDependentTechs(new Tech[]{});
    }
}

public enum TechState {
    RESEARCHED, RESEARCHING, AVAILABLE, UNAVAILABLE;
}