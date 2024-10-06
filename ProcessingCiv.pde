import java.util.Map;
import java.util.List;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Random;
import java.util.Stack;

// In order of render
public PGraphics boardG;
public PGraphics unitG;
public PGraphics highlightG;

public PGraphics cityDarkG;
public PGraphics cityMaskG;
public PGraphics knownDarkG;
public PGraphics cityBoundariesG;

public PGraphics guiG;
public PGraphics menuG;

public HashMap<Biome, List<TerrainTileRule>> terrainTileRules = new HashMap<>();
public ArrayList<BiomeRule> biomeRules = new ArrayList<>();
public HashMap<AxialCoord, HexEdge> sharedEdgeFromMove = new HashMap<>();

public HashMap<CivName, Civ> civs = new HashMap<CivName, Civ>();
public ArrayList<Civ> turnOrder = new ArrayList<Civ>();

private PImage tilesheet;
private PImage trailsheet;
public static PImage[] tileImgs;
public static PImage[] trailImgs;

public PImage nextTurnImg;
public PImage settleImg;
public PImage farmImg;
public PImage automateImg;


public PImage goldImg;
public PImage happiness_lividImg;
public PImage happiness_unhappyImg;
public PImage happiness_happyImg;
public PImage scienceImg;
public PImage cultureImg;

public PImage red_targetImg;

public Board board;
public BoardClickHandler boardClickHandler;
public GUI gui;
public Civ thisCiv;

private int boardLengthX;
private int boardLengthY;
private float negOffsetX = 0;
private float negOffsetY = 0;

public PFont font;

public Unit selectedUnit = null;
public boolean isAttacking = false;
public City selectedCity = null;
public HashMap<AxialCoord, Integer> validMoves = new HashMap<>();
public Set<Unit> enemies = new HashSet<>();
public Set<City> enemyCities = new HashSet<>();
public Set<AxialCoord> embarkCoords = new HashSet<>();

public static Random random;
public final static float sqrt_3 = sqrt(3);

AxialCoord[] directions = {new AxialCoord(1,0), new AxialCoord(0,1), new AxialCoord(-1,1), new AxialCoord(-1,0), new AxialCoord(0,-1), new AxialCoord(1,-1)};

// INITS

void initTablesHash() {
    biomeRules.add(new BiomeRule(0.7f, Float.MAX_VALUE, 0f, Float.MAX_VALUE, 0f, Float.MAX_VALUE, Biome.MOUNTAIN));
    biomeRules.add(new BiomeRule(0f, 0.3f, 0f, Float.MAX_VALUE, 0f, Float.MAX_VALUE, Biome.OCEAN));
    biomeRules.add(new BiomeRule(0f, 0.4f, 0f, Float.MAX_VALUE, 0f, Float.MAX_VALUE, Biome.LAKE));
    biomeRules.add(new BiomeRule(0f, Float.MAX_VALUE, 0f, Float.MAX_VALUE, 0f, 0.2f, Biome.SNOW));
    biomeRules.add(new BiomeRule(0f, Float.MAX_VALUE, 0.7f, Float.MAX_VALUE, 0f, 0.6f, Biome.SWAMP));
    biomeRules.add(new BiomeRule(0f, Float.MAX_VALUE, 0f, 0.7f, 0f, 0.6f, Biome.GRASS));
    biomeRules.add(new BiomeRule(0f, Float.MAX_VALUE, 0f, Float.MAX_VALUE, 0.6f, Float.MAX_VALUE, Biome.DESERT));
    
    terrainTileRules.put(Biome.MOUNTAIN, new ArrayList<>(Arrays.asList(
        new TerrainTileRule(Float.MIN_VALUE, Float.MAX_VALUE, Float.MIN_VALUE, Float.MAX_VALUE, TileType.MOUNTAIN)
    )));
    
    terrainTileRules.put(Biome.OCEAN, new ArrayList<>(Arrays.asList(
        new TerrainTileRule(Float.MIN_VALUE, Float.MAX_VALUE, Float.MIN_VALUE, Float.MAX_VALUE, TileType.OCEAN)
    )));
    
    terrainTileRules.put(Biome.LAKE, new ArrayList<>(Arrays.asList(
        new TerrainTileRule(Float.MIN_VALUE, Float.MAX_VALUE, Float.MIN_VALUE, Float.MAX_VALUE, TileType.LAKE)
    )));
    
    terrainTileRules.put(Biome.SNOW, Arrays.asList(
        new TerrainTileRule(0f, 0.5f, 0f, 0.5f, TileType.SNOWLAND),
        new TerrainTileRule(0f, 0.5f, 0.5f, 0.7f, TileType.SPARSE_FOREST_SNOWLAND),
        new TerrainTileRule(0f, 0.5f, 0.7f, Float.MAX_VALUE, TileType.DENSE_FOREST_SNOWLAND),
        new TerrainTileRule(0.5f, Float.MAX_VALUE, 0f, 0.5f, TileType.HILL_SNOWLAND),
        new TerrainTileRule(0.5f, Float.MAX_VALUE, 0.5f, Float.MAX_VALUE, TileType.FORESTED_HILL_SNOWLAND)
    ));
    terrainTileRules.put(Biome.SWAMP, Arrays.asList(
        new TerrainTileRule(0f, Float.MAX_VALUE, 0f, 0.75f, TileType.MARSH_GRASS),
        new TerrainTileRule(0f, Float.MAX_VALUE, 0.75f, 0.8f, TileType.SPARSE_MARSH),
        new TerrainTileRule(0f, Float.MAX_VALUE, 0.8f, 0.9f, TileType.DENSE_MARSH),
        new TerrainTileRule(0f, Float.MAX_VALUE, 0.9f, Float.MAX_VALUE,  TileType.BOG)
    ));
    terrainTileRules.put(Biome.GRASS, Arrays.asList(
        new TerrainTileRule(0f, 0.8f, 0f, 0.5f, TileType.GRASSLAND),
        new TerrainTileRule(0f, 0.8f, 0.5f, 0.7f, TileType.SPARSE_FOREST_GRASSLAND),
        new TerrainTileRule(0f, 0.8f, 0.7f, Float.MAX_VALUE, TileType.DENSE_FOREST_GRASSLAND),
        new TerrainTileRule(0.8f, Float.MAX_VALUE, 0f, 0.5f, TileType.HILL_GRASSLAND),
        new TerrainTileRule(0.8f, Float.MAX_VALUE, 0.5f, Float.MAX_VALUE, TileType.FORESTED_HILL_GRASSLAND)
    ));
    terrainTileRules.put(Biome.DESERT, Arrays.asList(
        new TerrainTileRule(0.4f, 0.5f, 0f, Float.MAX_VALUE, TileType.SAND),
        new TerrainTileRule(0.5f, 0.6f, 0f, Float.MAX_VALUE, TileType.HILL_SAND),
        new TerrainTileRule(0.6f, 0.65f, 0f, Float.MAX_VALUE, TileType.DUNE_SAND),
        new TerrainTileRule(0.65f, 0.7f, 0f, Float.MAX_VALUE, TileType.CLIFF_SAND)
    ));
    
    for (int i=0; i<directions.length; i++) {
        float startAngle = TWO_PI / 6 * i;
        float endAngle = TWO_PI / 6 * ((i+1)%directions.length);
        sharedEdgeFromMove.put(directions[i], new HexEdge(
            hexRadius*cos(startAngle), hexRadius*(sin(startAngle)+sqrt_3/3), hexRadius*cos(endAngle), hexRadius*(sin(endAngle)+sqrt_3/3)
        ));
        //println(hexRadius*cos(startAngle), hexRadius*sin(startAngle), hexRadius*cos(endAngle), hexRadius*sin(endAngle));
    }
}

void initTiles() {
    boardG = createGraphics(boardLengthX, boardLengthY, P2D);
    boardG.imageMode(CENTER);
    
    tilesheet = loadImage("assets/fantasyhextiles_v3.png");
    tileImgs = new PImage[41];
    for (int i = 0; i < 41; i++) {
        // Calculate the x, y position based on the grid layout
        int x = (i % 8) * 32;
        int y = (i / 8) * 48;

        // Extract each sprite from the spritesheet
        tileImgs[i] = tilesheet.get(x, y, 32, 48);
    }

    trailsheet = loadImage("assets/fantasyhextiles_randr_4_v1.png");
    trailImgs = new PImage[20];
    for (int i = 0; i < 20; i++) {
        int x = (i % 8) * 32;
        int y = (i / 8) * 48 + 48;

        trailImgs[i] = trailsheet.get(x, y, 32, 48);
    }

    ResourceType.COTTON.setImg(loadImage("assets/resource_icons/icon_resource_cotton.png"));
    ResourceType.HORSES.setImg(loadImage("assets/resource_icons/icon_resource_horses.png"));
    ResourceType.IRON.setImg(loadImage("assets/resource_icons/icon_resource_iron.png"));
}

private void initUnits() {
    unitG = createGraphics(boardLengthX, boardLengthY, P2D);
    unitG.imageMode(CENTER);
    
    UnitType.SCOUT.setImg(loadImage("assets/unit_icons/icon_unit_scout_outline.png"));
    UnitType.ARCHER.setImg(loadImage("assets/unit_icons/icon_unit_archer_outline.png"));
    UnitType.SETTLER.setImg(loadImage("assets/unit_icons/icon_unit_settler_outline.png"));
    UnitType.WORKER.setImg(loadImage("assets/unit_icons/icon_unit_worker_outline.png"));
    UnitType.GALLEY.setImg(loadImage("assets/unit_icons/icon_unit_galley_outline.png"));
    UnitType.QUAD.setImg(loadImage("assets/unit_icons/icon_unit_quad_outline.png"));
    UnitType.TRADER.setImg(loadImage("assets/unit_icons/icon_unit_trader_outline.png"));
    UnitType.NONE.setImg(loadImage("assets/none_outline.png"));
}

private void initCivs() {
    goldImg = loadImage("assets/yield_icons/gold.png");
    happiness_lividImg = loadImage("assets/yield_icons/happiness_livid.png");
    happiness_unhappyImg = loadImage("assets/yield_icons/happiness_unhappy.png");
    happiness_happyImg = loadImage("assets/yield_icons/happiness_happy.png");
    scienceImg = loadImage("assets/yield_icons/science.png");
    cultureImg = loadImage("assets/yield_icons/culture.png");
    
    for (Civ civ : civs.values()) {
        civ.initHUDG();
        civ.renderHUD();
    }
    CivName.CHINA.setIcon(loadImage("assets/civ_icons/china_icon.png"));
    CivName.AMERICA.setIcon(loadImage("assets/civ_icons/america_icon.png"));
    CivName.FRANCE.setIcon(loadImage("assets/civ_icons/france_icon.png"));
}

private void initImprovements() {
    ImprovementType.FARM.setImg(tileImgs[11]);
}

private void initHighlights() {
    highlightG = createGraphics(boardLengthX, boardLengthY, P2D);
}

private void initCityBoundaries() {
    cityBoundariesG = createGraphics(boardLengthX, boardLengthY, P2D);
}

private void initUnknowns() {
    cityMaskG = createGraphics(boardLengthX, boardLengthY, P2D);
    cityDarkG = createGraphics(boardLengthX, boardLengthY, P2D);
    knownDarkG = createGraphics(boardLengthX, boardLengthY, P2D);

    knownDarkG.beginDraw();
    knownDarkG.translate(negOffsetX, negOffsetY);
    knownDarkG.fill(#000032);
    for (Tile tileToDarken : board.getTileMapTiles()) {
        hexagon(knownDarkG, tileToDarken.getX(), tileToDarken.getY(), false);
    }
    knownDarkG.endDraw();

    for (Civ civ : civs.values()) {
        civ.initKnownMaskG();
        for (Unit unit : civ.getCivUnitMapUnits()) {
            unit.addVisibleTiles();
        }
        long startTime3 = System.currentTimeMillis();
        civ.renderUnknown();
        println("Time to Render Unknown:", System.currentTimeMillis()-startTime3);
    }
    thisCiv.maskUnknown();
}

private void initCityMarkers() {
    for (Civ civ : civs.values()) {
        civ.initCityMarkerG();
    }
    red_targetImg = loadImage("assets/red_target.png");
}

private void initResearch() {
    Tech.POTTERY.setImg(loadImage("assets/research_icons/pottery_icon.png"));
    Tech.ANIMAL_HUSBANDRY.setImg(loadImage("assets/research_icons/animal_husbandry_icon.png"));
    Tech.ARCHERY.setImg(loadImage("assets/research_icons/archery_icon.png"));
    Tech.MINING.setImg(loadImage("assets/research_icons/mining_icon.png"));
}

ProductionMenu productionMenu;

private void initGUI() {
    GUIType.NEXTTURN.setImg(loadImage("assets/gui_icons/nextTurnImg.png"));
    GUIType.SETTLE.setImg(loadImage("assets/gui_icons/settleImg.png"));
    GUIType.FARM.setImg(loadImage("assets/gui_icons/farmImg.png"));
    GUIType.AUTOMATE.setImg(loadImage("assets/gui_icons/automateImg.png"));
    GUIType.RESEARCH.setImg(loadImage("assets/gui_icons/researchImg.png"));
    GUIType.CLOSERESEARCH.setImg(loadImage("assets/gui_icons/close.png"));
    
    guiG = createGraphics(boardLengthX, boardLengthY, P2D);
    guiG.rectMode(CORNER);
    gui = new GUI();
    gui.render();
    
    menuG = createGraphics(boardLengthX, boardLengthY, P2D);
}

private void spawnCivs() {
    thisCiv = turnOrder.get(0);
    for (Civ civ : civs.values()) {
        board.spawn(civ);
    }
    thisCiv.snapToUnit();
}

private void createCiv(CivName name, Civ civ) {
    civs.put(name, civ);
    turnOrder.add(civ);
}

// HELPER FUNCTIONS

public void hexagon(PGraphics pg, float centerX, float centerY, boolean boundaries) {
    pg.beginShape();
    for (int i = 0; i < 6; i++) {
        float angle = TWO_PI / 6 * i;
        float radius = hexRadius;
        if (boundaries) {
            radius += 4;
        }
        float x = centerX + radius * cos(angle);
        float y = (centerY + radius/2 + radius * sin(angle));
        pg.vertex(x, y);
    }
    pg.endShape(CLOSE);
}

public <K, V> void addToMap(Map<K, List<V>> map, K key, V value) {
    map.computeIfAbsent(key, k -> new ArrayList<>()).add(value);
}

public <K, V> void addToMapStack(Map<K, Stack<V>> map, K key, V value) {
    map.computeIfAbsent(key, k -> new Stack<>()).push(value);
}

public <K, V> void popFromStack(Map<K, Stack<V>> map, K key) {
    if (map.containsKey(key)) {
        Stack<V> stack = map.get(key);
        if (!stack.isEmpty()) {
            stack.pop();
            if (stack.isEmpty()) {
                map.remove(key);
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public int bs = 10;
public float noiseScale = 0.2;
public final static int hexRadius = 50;

void setup() {
    frameRate(144);
    size(1000, 1000, P2D);
    noiseDetail(20,0.5);
    noiseSeed(10);
    random = new Random();
    font = createFont("assets/fonts/Tw Cen MT.ttf", 128, true);
    boardLengthX = round((2*bs-1) * hexRadius * sqrt_3);
    boardLengthY = round((2*bs-1) * hexRadius * 2);
    // Formula for negOffsets or make preset sizes
    negOffsetX = boardLengthX*1.43;
    negOffsetY = hexRadius;
    println(negOffsetX, negOffsetY);
    
    // long startTime = System.currentTimeMillis();

    // long initTilesTime = System.currentTimeMillis();
    initTiles();
    // println("Time to Init Tiles:", System.currentTimeMillis()-initTilesTime);
    // long initTablesTime = System.currentTimeMillis();
    initTablesHash();
    // println("Time to Init Tables:", System.currentTimeMillis()-initTablesTime);
    // long boardTime = System.currentTimeMillis();
    board = new Board();
    // println("Time to Init Board:", System.currentTimeMillis()-boardTime);
    // long boardClickTime = System.currentTimeMillis();
    boardClickHandler = new BoardClickHandler();
    // println("Time to Init Board Click Handler:", System.currentTimeMillis()-boardClickTime);
    // long generateBoardTime = System.currentTimeMillis();
    board.generateBoard();

    initResearch();
    // println("Time to Generate Board:", System.currentTimeMillis()-generateBoardTime);
    // long initCivsTime = System.currentTimeMillis();
    createCiv(CivName.AMERICA, new Civ(CivName.AMERICA));
    createCiv(CivName.CHINA, new Civ(CivName.CHINA));
    createCiv(CivName.FRANCE, new Civ(CivName.FRANCE));
    // println("Time to Init Civs:", System.currentTimeMillis()-initCivsTime);
    // long initUnitsTime = System.currentTimeMillis();
    initUnits();
    // println("Time to Init Units:", System.currentTimeMillis()-initUnitsTime);
    // long initCivsTime2 = System.currentTimeMillis();
    initCivs(); // Just loads civ icons
    // println("Time to Init Civs 2:", System.currentTimeMillis()-initCivsTime2);
    // long spawnCivsTime = System.currentTimeMillis();
    spawnCivs();
    // println("Time to Spawn Civs:", System.currentTimeMillis()-spawnCivsTime);
    // long initImprovementsTime = System.currentTimeMillis();
    initImprovements(); // Just loads improvement imgs
    // println("Time to Init Improvements:", System.currentTimeMillis()-initImprovementsTime);
    // long initCityBoundariesTime = System.currentTimeMillis();
    initCityBoundaries();
    // println("Time to Init City Boundaries:", System.currentTimeMillis()-initCityBoundariesTime);
    // long initHighlightsTime = System.currentTimeMillis();
    initHighlights();
    // println("Time to Init Highlights:", System.currentTimeMillis()-initHighlightsTime);
    long initUnknownsTime = System.currentTimeMillis();
    initUnknowns();
    println("Time to Init Unknowns:", System.currentTimeMillis()-initUnknownsTime);
    // long initCityMarkersTime = System.currentTimeMillis();
    initCityMarkers();
    // println("Time to Init City Markers:", System.currentTimeMillis()-initCityMarkersTime);
    // long initGUITime = System.currentTimeMillis();
    initGUI();
    // println("Time to Init GUI:", System.currentTimeMillis()-initGUITime);

    // println("Time to Generate:", System.currentTimeMillis()-startTime);
    
}

float startX = 0;
float startY = 0;
float offsetX = 0;
float offsetY = 0;

boolean isDragging = false;
float minZoom = 0.25;
float maxZoom = 2;
float zoomFactor = 0.8; // Default zoom level is 1 (no zoom)
float scrollFactor = 1.0;
int scrollCoefficient = 50;

AxialCoord prevHover = null;

void mouseMoved() {
    if (selectedUnit != null && selectedUnit.getType() != UnitType.TRADER) {
        AxialCoord hoverCoord = cartesianToAxial(mouseX, mouseY);
        if (board.isWithinBounds(hoverCoord.getQ(), hoverCoord.getR()) && (prevHover == null || !prevHover.equals(hoverCoord))) {
            if (!board.isUnitAtCoord(hoverCoord)) {
                board.renderHover(hoverCoord);
            }
            if (prevHover != null) {
                board.clearHover(prevHover);
            }
            // If hovering over unit, clear hover if it exists. If not hovering over unit, render hover and clear previous hover if it exists
            prevHover = hoverCoord;
        } else if (!board.isWithinBounds(hoverCoord.getQ(), hoverCoord.getR()) && prevHover != null) {
            board.clearHover(prevHover);
            prevHover = null;
        }
    }
}

void draw() {
    background(#000032);
    // Draw scalable elements
    translate(offsetX, offsetY); // Center the zoom on the canvas
    scale(zoomFactor); // Apply the current zoom level

    image(boardG, 0, 0);
    image(unitG, 0, 0);
    image(cityBoundariesG, 0, 0);
    image(highlightG, 0, 0);
    image(cityDarkG, 0, 0);
    image(knownDarkG, 0, 0);
    image(thisCiv.getCityMarkerG(), 0, 0);
    
    // Non-scalable elements
    resetMatrix();
    image(menuG, 0, 0);
    image(guiG, 0, 0);
    image(thisCiv.getHUDG(), 0, 0);
}

public void snapCamera(float unitX, float unitY) {
    // Desired screen position for the unit, e.g., the center of the screen
    float centerX = width / 2.0f;
    float centerY = height / 2.0f;

    // Calculate the offsets needed to position the unit at the center of the screen
    // Consider that unitG.translate(negOffsetX, negOffsetY) has been used in rendering
    offsetX = centerX - (unitX + negOffsetX) * zoomFactor;
    offsetY = centerY - ((unitY + hexRadius * 0.5) + negOffsetY) * zoomFactor;
}

void mousePressed() {
    if (mouseButton == LEFT) {
        startX = mouseX - offsetX;
        startY = mouseY - offsetY;
        isDragging = true;
    } else if (mouseButton == CENTER) {
        offsetX = round(mouseX - (1/zoomFactor) * (mouseX - offsetX));
        offsetY = round(mouseY - (1/zoomFactor) * (mouseY - offsetY));
        zoomFactor = 1;
    }
}

void mouseReleased() {
    isDragging = false;
}

void mouseDragged() {
    if (isDragging) {
        offsetX = mouseX - startX;
        offsetY = mouseY - startY;
    }
}


public CubeCoord axial_to_cube(float q, float r) {
    return new CubeCoord(q, r, -q-r);
}

public AxialCoord cube_to_axial(CubeCoord cube) {
    return new AxialCoord((int) cube.getQ(), (int) cube.getR());
}

public CubeCoord cube_round(CubeCoord cube) {
    int q = round(cube.getQ());
    int r = round(cube.getR());
    int s = round(cube.getS());

    float q_diff = abs(q - cube.getQ());
    float r_diff = abs(r - cube.getR());
    float s_diff = abs(s - cube.getS());

    if (q_diff > r_diff && q_diff > s_diff) {
        q = -r-s;
    } else if (r_diff > s_diff) {
        r = -q-s;
    } else {
        s = -q-r;
    }

    return new CubeCoord(q, r, s);
}

public AxialCoord cartesianToAxial(float x, float y) {
    float adjustedX = ((x - offsetX) / zoomFactor) - negOffsetX + hexRadius/2;
    float adjustedY = ((y - offsetY) / zoomFactor) - negOffsetY + (2*hexRadius)/3;
    float q = ((2*adjustedX) / (3 * hexRadius)) - 10 + bs*3;
    float r = ((adjustedY * sqrt_3 - adjustedX) / (3 * hexRadius)) - bs*2 - 1;
    return cube_to_axial(cube_round(axial_to_cube(q, r)));
}

void mouseClicked() {
    GUIElement element = gui.elementClicked();
    
    AxialCoord clickCoord = cartesianToAxial(mouseX, mouseY);
    
    if (element != null) {
        if (element.getType() == GUIType.SETTLE) {
            thisCiv.addCity();
        } else if (element.getType() == GUIType.FARM) {
            ((CivilianUnit) selectedUnit).improveTile(ImprovementType.FARM);
        } else if (element.getType() == GUIType.NEXTTURN) {
            board.nextTurn();
        } else if (element.getType() == GUIType.AUTOMATE) {
            board.addUnitToAutomate((MeleeUnit) selectedUnit);
            ((MeleeUnit) selectedUnit).automate();
        } else if (element.getType() == GUIType.RESEARCH) {
            thisCiv.firstRenderTechTree();
        } else if (element.getType() == GUIType.CLOSERESEARCH) {
            thisCiv.closeResearch();
        }
    } else {
        if (selectedCity == null) {
            if (!boardClickHandler.citySelector(clickCoord)) {
                if (board.getState() == State.TRADER) {
                    Object option = productionMenu.optionClicked();
                    if (option != null) {
                        print((CivilianUnit) selectedUnit, (City) option);
                        ((CivilianUnit) selectedUnit).trade((City) option);
                    }
                } else {
                    boardClickHandler.unitSelector(clickCoord);
                }
            }
        } else {
            boardClickHandler.citySelector(clickCoord);
            
            if (board.getState() == State.PRODUCTION) {
                Object option = productionMenu.optionClicked();
                if (option != null && board.getState() == State.PRODUCTION) {
                    selectedCity.addProduction((UnitType) option, 2);
                }
            }
        }
    }
}


void mouseWheel(MouseEvent event) {
        float e = event.getCount();

        // Set the zoom factor based on the scroll direction

        if (board.getState() == State.PRODUCTION && (mouseX >= productionMenu.x && mouseX <= productionMenu.x+productionMenu.menuWidth && mouseY >= productionMenu.y && mouseY <= productionMenu.y+productionMenu.menuHeight)) {
            // Apply the new factor to the current zoom level
            float newScrollFactor = scrollFactor + e;
            newScrollFactor = constrain(newScrollFactor, 0, max(0, (productionMenu.getTotalHeight() - productionMenu.getMenuHeight())/scrollCoefficient));
            scrollFactor = Math.round(newScrollFactor * 10) / 10.0f;
    
            productionMenu.drawOptions();
        } else if (board.getState() == State.RESEARCH) {
            float newScrollFactor = scrollFactor + e;
            scrollFactor = Math.round(newScrollFactor * 10) / 10.0f;
    
            thisCiv.renderTechTree();
        } else {
            float factor = e > 0 ? 0.9 : 1.1;
            
            float newZoomFactor = zoomFactor * factor;
            newZoomFactor = constrain(newZoomFactor, minZoom, maxZoom);
            newZoomFactor = Math.round(newZoomFactor * 10) / 10.0f;
            // Calculate the translations needed to keep the image centered under the mouse
            offsetX = Math.round(mouseX - (newZoomFactor / zoomFactor) * (mouseX - offsetX));
            offsetY = Math.round(mouseY - (newZoomFactor / zoomFactor) * (mouseY - offsetY));
        
            // Update the zoom factor
            zoomFactor = newZoomFactor;
        }
}

void keyPressed() {
    if (keyCode == ENTER || keyCode == RETURN) {
        board.nextTurn();
    }
}
