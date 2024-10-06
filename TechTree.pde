private int eraHeight = 20;
private float scrollOffset = 0;
private int optionWidth;
private int optionHeight;
private int optionGapY;
private int optionGapX;

class TechTree {
    private ArrayList<TechOption> techOptions = new ArrayList<TechOption>();
    private ArrayList<EraBar> eraBars = new ArrayList<EraBar>();

    public TechTree() {
        for (Tech tech : Tech.values()) {
            techOptions.add(new TechOption(tech));
        }
        eraBars.add(new EraBar("Ancient Era", 0, 2));

        optionWidth = width / 3;
        optionHeight = height / 14;
        optionGapY = (height - eraHeight - optionHeight * 10) / 11;
        optionGapX = width / 10;
    }

    public void drawOptions() {
        menuG.beginDraw();
        menuG.background(#000032);
        menuG.imageMode(CENTER);
        menuG.ellipseMode(CENTER);
        menuG.textAlign(CENTER, CENTER);
        for (TechOption techOption: techOptions) {
            techOption.render();
        }
        for (EraBar eraBar: eraBars) {
            eraBar.render();
        }
        menuG.endDraw();
    }

    public void close() {
        board.setState(State.GAME);
        gui.show(GUIType.RESEARCH, true);
        gui.show(GUIType.NEXTTURN, true);
        gui.hide(GUIType.CLOSERESEARCH);
        menuG.beginDraw();
        menuG.clear();
        menuG.endDraw();
    }

    public TechOption optionClicked() {
        for (TechOption techOption: techOptions) {
            float x = techOption.getCol() * (optionWidth + optionGapX) + scrollOffset + optionGapX/2;
            float y = techOption.getRow() * (optionHeight + optionGapY) + eraHeight + optionGapY;
            if (mouseX >= x + scrollOffset && mouseX <= x + optionWidth + scrollOffset  && mouseY >= y && mouseY <= y + optionHeight) {
                return techOption;
            }
        }
        return null;
    }
}

class TechOption {
    private PImage img;
    private Tech tech;
    private int col, row;
    private Tech[] dependentTechs;
    
    public TechOption(Tech _tech) { 
        tech = _tech;
        img = _tech.getImg();
        col = _tech.getCol();
        row = _tech.getRow();
        dependentTechs = _tech.getDependentTechs();
    }

    public int getCol() {return col;}
    public int getRow() {return row;}
    public Tech getTech() {return tech;}

    public void render() {
        float scrollOffset = constrain(scrollFactor * 50, -1000, 0);
        scrollFactor = constrain(scrollFactor, -20, 0);
        float x = col * (optionWidth + optionGapX) + scrollOffset + optionGapX/2;
        float y = row * (optionHeight + optionGapY) + eraHeight + optionGapY;
        // Draw the rectangle for this TechOption
        color rectColor = #07120f;
        color textColor = 255;
        switch(thisCiv.getTechState(tech)) {
            case RESEARCHED:
                rectColor = #D4AF37;
                textColor = #5e4e19;
                break;
            case RESEARCHING:
                rectColor = #13594f;
                break;
            case AVAILABLE: 
                rectColor = #32a701;
                break;
        }
        menuG.fill(rectColor);
        menuG.strokeWeight(10);
        menuG.stroke(rectColor);
        menuG.rect(x, y, optionWidth, optionHeight, 10);
        
        menuG.fill(#B59410);
        menuG.noStroke();
        menuG.circle(x+optionHeight/2, y+optionHeight/2, optionHeight-8);
        if (img != null) {
            menuG.image(img, x+optionHeight/2, y+optionHeight/2, 5*optionHeight/6, 5*optionHeight/6);
        }
        
        menuG.fill(0);
        menuG.noStroke();
        menuG.rect(x + optionWidth/4, y + optionHeight/4, 3*optionWidth/4, 3*optionHeight/4, 10);
        
        // Set text properties and draw the tech in the center of the rectangle
        menuG.fill(textColor);
        menuG.textSize(15);
        menuG.textAlign(LEFT);
        menuG.text(tech.getName(), x + optionWidth/4, y + optionHeight/6);
    
        // Draw connections to dependent technologies
        menuG.strokeWeight(2);
        menuG.stroke(255);
        for (Tech tech : dependentTechs) {
            float techX = tech.getCol() * (optionWidth + optionGapX) + scrollOffset + optionGapX;
            float techY = tech.getRow() * (optionHeight + optionGapY) + eraHeight + optionGapY;
            drawZigzagPath(x + optionWidth, y + optionHeight / 2, techX, techY + optionHeight / 2, 10);
        }
    }
}

class EraBar {
    private String tech;
    private int startCol, endCol;
    
    public EraBar(String _tech, int _startCol, int _endCol) {
        tech = _tech;
        startCol = _startCol;
        endCol = _endCol;
    }
    
    public void render() {
        float startX = startCol * (optionWidth + optionGapX) + scrollOffset;
        float eraWidth = (optionWidth + optionGapX) * (endCol-startCol+1) + optionGapX/2;
        color rectColor = #07120f;
        color textColor = 255;
        int researchingCol = thisCiv.getResearchingCol();
        if (researchingCol != -1 && researchingCol >= startCol && researchingCol <= endCol) {
            switch(thisCiv.getResearchingState()) {
                case RESEARCHED:
                    rectColor = #D4AF37;
                    textColor = #5e4e19;
                    break;
                case RESEARCHING:
                    rectColor = #13594f;
                    break;
                case AVAILABLE: 
                    rectColor = #32a701;
                    break;
            }
        }
        // Draw the rectangle for this TechOption
        menuG.fill(rectColor);
        menuG.stroke(#B59410);
        menuG.rect(startX, 0, eraWidth, eraHeight);
        menuG.fill(textColor);
        menuG.textSize(15);
        menuG.text(tech, startX + eraWidth / 2, eraHeight / 2);
    }
}

public void drawZigzagPath(float x1, float y1, float x2, float y2, float radius) {
    menuG.noFill();
    float midX = (x1 + x2) / 2 - 2*radius;
    
    if (y2 > y1) {
        menuG.line(x1, y1, midX-radius, y1);
        menuG.arc(midX-radius, y1+radius, 2*radius, 2*radius, -HALF_PI, 0);
        menuG.line(midX, y1+radius, midX, y2-radius);
        menuG.arc(midX+radius, y2-radius, 2*radius, 2*radius, HALF_PI, PI);
        menuG.line(midX+radius, y2, x2, y2);
    } else if (y2 < y1) {
        menuG.line(x1, y1, midX-radius, y1);
        menuG.arc(midX-radius, y1-radius, 2*radius, 2*radius, 0, HALF_PI);
        menuG.line(midX, y1-radius, midX, y2+radius);
        menuG.arc(midX+radius, y2+radius, 2*radius, 2*radius, PI, PI*1.5);
        menuG.line(midX+radius, y2, x2, y2);
    } else {
        menuG.line(x1, y1, x2, y2);
    }
}

public enum Era {
    ANCIENT, CLASSICAL, MEDIEVAL, RENAISSANCE, INDUSTRIAL, MODERN, ATOMIC, INFORMATION;
}