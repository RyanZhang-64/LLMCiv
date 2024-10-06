import java.util.Queue;
import java.util.HashSet;
import java.util.LinkedList;

class Tile {
    private int q, r;
    private float x, y;
    private Biome biome;
    private TileType type;

    private ResourceType resource;
    private ImprovementType improvement;

    private boolean isRiver;
    
    public Tile(int _q, int _r, float _x, float _y, Biome _biome, TileType _type, ResourceType _resource) { // If resource generation is single-tile-considering
        q = _q;
        r = _r;
        x = _x;
        y = _y;
        biome = _biome;
        type = _type;

        resource = _resource;
        improvement = null;
    }
    
    public void render() {
        // Use the image's center and scale it to fit the hexagon
        boardG.image(type.getImg(), x, y, hexRadius*2, hexRadius*3);
        if (resource != null) {
            boardG.image(resource.getImg(), x, y+0.5*hexRadius, hexRadius*0.5, hexRadius*0.5);
        }
        //boardG.text(q + " " + r, x-10, y+10);
    }

    public void render(PImage img) {
        // Use the image's center and scale it to fit the hexagon
        boardG.image(img, x, y, hexRadius*2, hexRadius*3);
        if (resource != null) {
            boardG.image(resource.getImg(), x, y+0.5*hexRadius, hexRadius*0.5, hexRadius*0.5);
        }
        //boardG.text(q + " " + r, x-10, y+10);
    }
    
    public int getQ() {return q;}
    public int getR() {return r;}
    public float getX() {return x;}
    public float getY() {return y;}
    public Biome getBiome() {return biome;}
    public TileType getType() {return type;}
    
    public AxialCoord getHex() {return new AxialCoord(q,r);}
    public ResourceType getResource() {return resource;}
    
    public void addRiver() {isRiver = true;}

    public void setImprovement(ImprovementType _improvement, City city) {
        improvement = _improvement;
        boardG.beginDraw();
        boardG.translate(negOffsetX, negOffsetY);
        boardG.image(_improvement.getImg(), x, y, (hexRadius-4)*2, (hexRadius-4)*3);
        boardG.endDraw();

        city.addFoodPT(_improvement.getQuantities()[0]);
    }
    
    public void makeCityCenter() {
        PImage img;
        switch (biome) {  
            case SNOW:
                img = tileImgs[22];
                break;
            case SWAMP:
            case GRASS:
                img = tileImgs[8];
                break;
            default:
                img = tileImgs[30];
                break;
        }
        boardG.beginDraw();
        boardG.translate(negOffsetX, negOffsetY);
        render(img);
        boardG.endDraw();
    }
    
    public boolean isArable() {
        return type != TileType.MOUNTAIN && type != TileType.OCEAN && type != TileType.LAKE && improvement == null;
    }
}

public enum ImprovementType {
    FARM(2, new YieldType[]{YieldType.FOOD}, new int[]{2});
    
    private int turnsToFinish;
    private YieldType[] attributes;
    private int[] quantities;
    private PImage img;
    
    ImprovementType(int _turnsToFinish, YieldType[] _attributes, int[] _quantities) {
        turnsToFinish = _turnsToFinish;
        attributes = _attributes;
        quantities = _quantities;
    }
    
    public int getTurnsToFinish() {return turnsToFinish;}
    public YieldType[] getAttributes() {return attributes;}
    public int[] getQuantities() {return quantities;}
    
    public void setImg(PImage _img) {img = _img;}
    public PImage getImg() {return img;}
}

public enum Biome {
    MOUNTAIN, OCEAN, LAKE, SNOW, SWAMP, GRASS, DESERT
}

public enum TileType {
    MOUNTAIN(10000, 0, 5),
    OCEAN(10000, 1, 7),
    LAKE(10000, 1, 6),
    SNOWLAND(1, 0, 16), SPARSE_FOREST_SNOWLAND(2, 0, 17), DENSE_FOREST_SNOWLAND(2, 0, 18), HILL_SNOWLAND(2, 0, 19), FORESTED_HILL_SNOWLAND(3, 0, 20),
    BOG(3, 1, 12), DENSE_MARSH(2, 1, 13), SPARSE_MARSH(2, 1, 14), MARSH_GRASS(1, 1, 15),
    GRASSLAND(1, 2, 0), SPARSE_FOREST_GRASSLAND(2, 2, 1), DENSE_FOREST_GRASSLAND(2, 2, 2), HILL_GRASSLAND(2, 2, 3), FORESTED_HILL_GRASSLAND(3, 2, 4),
    SAND(1, 0, 26), HILL_SAND(2, 0, 24), DUNE_SAND(2, 0, 25), CLIFF_SAND(3, 0, 27);
    
    private int travelCost;
    private int foodYield;
    private int imgIndex;
    
    TileType(int _travelCost, int _foodYield, int _imgIndex) {
        travelCost = _travelCost;
        foodYield = _foodYield;
        imgIndex = _imgIndex;
    }
    
    public PImage getImg() {return tileImgs[imgIndex];}
    public int getTravelCost() {return travelCost;}
    public int getVisibilityCost() {
        if (this == TileType.OCEAN || this == TileType.LAKE || this == TileType.MOUNTAIN) {
            return 1;
        } else {
            return travelCost;
        }
    }
    public int getSeaTravelCost() {
        if (this == TileType.OCEAN || this == TileType.LAKE) {
            return 1;
        } else {
            return 10000;
        }
    }
    public boolean isVisibilityOccluder() {
        if (this == TileType.MOUNTAIN) {
            return true;
        } else {
            return false;
        }
    }
    public boolean isRangedOccluder() {
        if (this == TileType.OCEAN || this == TileType.LAKE || this == TileType.SNOWLAND || this == TileType.GRASSLAND || this == TileType.SAND) {
            return false;
        } else {
            return true;
        }
    }
    public boolean isWater() {
        return this == TileType.OCEAN || this == TileType.LAKE;
    }
    public boolean isImpassable(boolean isLand, boolean canEmbark) {
        if (!canEmbark) {
            if (isLand) {
                return this == TileType.OCEAN || this == TileType.LAKE || this == TileType.MOUNTAIN || this == TileType.CLIFF_SAND;
            } else {
                return this != TileType.OCEAN && this != TileType.LAKE;
            }
        } else {
            return this == TileType.MOUNTAIN || this == TileType.CLIFF_SAND;
        }
    }
    public int getFoodYield() {return foodYield;}
}

public enum ResourceType {
    COTTON(YieldType.GOLD, 2, true), HORSES(YieldType.PRODUCTION, 1, false), IRON(YieldType.PRODUCTION, 1, false);

    private PImage img;
    private YieldType yieldType;
    private int yield;
    private boolean isLuxury;

    ResourceType(YieldType _yieldType, int _yield, boolean _isLuxury) {
        yieldType = _yieldType;
        yield = _yield;
        isLuxury = _isLuxury;
    }

    public YieldType getYieldType() {return yieldType;}
    public int getYield() {return yield;}
    public boolean isLuxury() {return isLuxury;}
    public PImage getImg() {return img;}
    public void setImg(PImage _img) {img = _img;}
}