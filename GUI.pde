class GUI {
    HashMap<GUIType, GUIElement> elements;
    HashSet<GUIElement> visibleElements;
  
    public GUI() {
        elements = new HashMap<GUIType, GUIElement>();
        visibleElements = new HashSet<GUIElement>();
        // GUITYPE, startX, startY, endX, endY, bbStartX, bbStartY, img, startVisible
        elements.put(GUIType.NEXTTURN, new GUIElement(GUIType.NEXTTURN, width-82, height-72, 61, width-175, height-200, GUIType.NEXTTURN.getImg(), true));
        elements.put(GUIType.SETTLE, new GUIElement(GUIType.SETTLE, width-204, height-15, 18, width-230, height-45, GUIType.SETTLE.getImg(), false));
        elements.put(GUIType.FARM, new GUIElement(GUIType.FARM, width-204, height-15, 18, width-230, height-45, GUIType.FARM.getImg(), false));
        elements.put(GUIType.AUTOMATE, new GUIElement(GUIType.AUTOMATE, width-204, height-15, 18, width-230, height-45, GUIType.AUTOMATE.getImg(), false));
        elements.put(GUIType.RESEARCH, new GUIElement(GUIType.RESEARCH, width-82, height-400, 61, width-175, height-528, GUIType.RESEARCH.getImg(), true));
        elements.put(GUIType.CLOSERESEARCH, new GUIElement(GUIType.CLOSERESEARCH, 20, height-60, GUIType.CLOSERESEARCH.getImg(), false));
        
        for (GUIElement element : elements.values()) {
            if (element.isStartVisible()) {
                visibleElements.add(element);
            }
        }
    }
    
    public void render() {
        guiG.beginDraw();
        
        for (GUIElement element : visibleElements) {
            float[] bb = element.getBB();
            guiG.image(element.getImg(), bb[0], bb[1], bb[2], bb[3]);
            /*if (element.isCircular()) {
                menuG.ellipse(element.getCenterX(), element.getCenterY(), 2*element.getRadius(), 2*element.getRadius());
            }*/
        }
        guiG.endDraw();
    }
    
    public GUIElement elementClicked() {
        for (GUIElement element : visibleElements) {
            if (element.isCircular()) {
                float x = element.getCenterX();
                float y = element.getCenterY();
                float radius = element.getRadius();
                // Check if the mouse is within the bounding box of the unit's radius
                if (mouseX >= x - radius && mouseX <= x + radius && mouseY >= y - radius && mouseY <= y + radius) {
                    float dx = mouseX - x;
                    float dy = mouseY - y;
                    if ((dx * dx + dy * dy) <= radius * radius) {
                        return element;
                    }
                }
            } else {
                float[] bb = element.getBB();
                if (mouseX >= bb[0] && mouseX <= bb[0]+bb[2] && mouseY >= bb[1] && mouseY <= bb[1]+bb[3]) {
                    return element;
                }
            }
        }
        return null;
    }
    
    public void show(GUIType type, boolean valid) {
        elements.get(type).show(valid);
        visibleElements.add(elements.get(type));
    }
    
    public void hide(GUIType type) {
        elements.get(type).hide();
        visibleElements.remove(elements.get(type));
    }
}

class GUIElement {
    GUIType type;
    boolean startVisible;
    // Ciruclar or rect
    boolean circular;
    // Rect
    float startX, startY, endX, endY;
    // Circular
    float centerX, centerY;
    float radius;
    
    float bbStartX, bbStartY, bbWidth, bbHeight;
    PImage img;
    
    public GUIElement(GUIType _type, float _startX, float _startY, PImage _img, boolean _startVisible) {
        type = _type;
        circular = false;
        bbStartX = _startX;
        bbStartY = _startY;
        img = _img;
        bbWidth = _img.width;
        bbHeight = _img.height;
        startVisible = _startVisible;
    }
    
    public GUIElement(GUIType _type, float _centerX, float _centerY, float _radius, float _bbStartX, float _bbStartY, PImage _img, boolean _startVisible) {
        type = _type;
        circular = true;
        centerX = _centerX;
        centerY = _centerY;
        radius = _radius;
        bbStartX = _bbStartX;
        bbStartY = _bbStartY;
        bbWidth = _img.width;
        bbHeight = _img.height;
        img = _img;
        startVisible = _startVisible;
    }
    
    public GUIType getType() {return type;}
    public boolean isStartVisible() {return startVisible;}
    
    public boolean isCircular() {return circular;}
    
    public float getCenterX() {return centerX;}
    public float getCenterY() {return centerY;}
    public float getRadius() {return radius;}
    
    public float getStartX() {return startX;}
    public float getStartY() {return startY;}
    
    public float[] getBB() {
        return new float[]{bbStartX, bbStartY, bbWidth, bbHeight};
    }
    
    public PImage getImg() {return img;}
    
    public void show(boolean valid) {
        guiG.beginDraw();
        PImage grayscaleImg = img.get();
        if (!valid) {
            grayscaleImg.loadPixels();
            
            for (int i = 0; i < grayscaleImg.pixels.length; i++) {
                // Extract the current color
                int c = grayscaleImg.pixels[i];
                int r = (c >> 16) & 0xFF;  // Red channel
                int g = (c >> 8) & 0xFF;   // Green channel
                int b = c & 0xFF;          // Blue channel
                int a = (c >> 24) & 0xFF;  // Alpha channel (transparency)
            
                // Calculate grayscale value
                int gray = int(0.299 * r + 0.587 * g + 0.114 * b);
            
                // Set the new color with the original alpha value
                grayscaleImg.pixels[i] = color(gray, gray, gray, a);
            }
          
            grayscaleImg.updatePixels();
        }
        guiG.image(grayscaleImg, bbStartX, bbStartY, bbWidth, bbHeight);
        guiG.endDraw();
    }
    
    public void hide() {
        guiG.beginDraw();
        guiG.blendMode(REPLACE);
        guiG.noStroke();
        guiG.fill(0, 0);
        guiG.rect(bbStartX, bbStartY, bbWidth, bbHeight);
        guiG.endDraw();
    }
}

public enum GUIType {
    NEXTTURN, SETTLE, FARM, AUTOMATE, RESEARCH, CLOSERESEARCH;

    private PImage img;
    public PImage getImg() {return img;}
    public void setImg(PImage _img) {img = _img;}
}