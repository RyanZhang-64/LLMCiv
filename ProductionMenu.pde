class ProductionMenu {
    ArrayList<Option> options;
    float x, y;
    float menuWidth, menuHeight;
    float scrollOffset;
    final int menuOffset;

    public ProductionMenu(ArrayList<Option> _options, float _x, float _y, float _menuWidth, float _menuHeight, int _menuOffset) {
        options = _options;
        x = _x;
        y = _y;
        menuWidth = _menuWidth;
        menuHeight = _menuHeight;
        scrollOffset = 0;
        menuOffset = _menuOffset;

        board.setState(State.PRODUCTION);
        scrollFactor = 0;
    }

    public float getMenuHeight() {
        return menuHeight;
    }

    void addOption(String label, UnitType item) {
        options.add(new Option(label, item));
    }

    void drawOptions() {
        scrollOffset = constrain(scrollFactor * 50, 0, max(0, getTotalHeight() - menuHeight));
        scrollFactor = constrain(scrollFactor, 0, max(0, getTotalHeight() - menuHeight)/50);
        menuG.beginDraw();
        /*menuG.textFont(font);
        menuG.fill(0,0,139,200);
        menuG.rect(0,20,200,20);
        menuG.textAlign(CENTER, CENTER);
        menuG.textSize(12);
        menuG.fill(255);
        menuG.text(selectedCity.getName(), 100, 100);
        menuG.fill(0);
        menuG.rect(0,40,200,80);
        menuG.textAlign(LEFT);
        menuG.textSize(20);
        menuG.fill(255);
        menuG.text(selectedCity.getPopulation()+" Citizens", 50, 130);
        menuG.textSize(16);
        menuG.text(selectedCity.estimatedTurnsToNextPopulation()+" Turns until a New Citizen is Born", 50, 170);*/
        menuG.fill(220);
        
        menuG.rect(10, menuOffset, menuWidth, menuHeight);
        menuG.clip(10, menuOffset, menuWidth, menuHeight); // Clip overflow outside the box

        float y = menuOffset - scrollOffset;
        for (Option option: options) {
            if (option.isVisible || option.isCategory) {
                option.display(10, y, menuWidth, option.isCategory ? 30 : 50);
                y += option.isCategory ? 30 : 50;
            }
        }
        
        menuG.noClip();
        menuG.endDraw();
    }

    public Object optionClicked() {
        if (mouseX > 10 && mouseX < 10 + menuWidth && mouseY > menuOffset && mouseY < menuOffset + menuHeight) {
            float y = menuOffset - scrollOffset;
            for (Option option: options) {
                float height = option.isCategory ? 30 : 50;
                if (option.isVisible || option.isCategory) {
                    if (mouseY > y && mouseY < y + height) {
                        if (option.isCategory) {
                            option.toggle();
                            drawOptions();
                            // Recalculate scroll offset to accommodate content changes
                        } else {
                            return option.item;
                        }
                        break;
                    }
                    y += height;
                }
            }
        }
        return null;
    }

    float getTotalHeight() {
        float total = 0;
        for (Option option: options) {
            if (option.isVisible || option.isCategory) { // Include categories regardless of expansion state
                total += option.isCategory ? 30 : 50;
            }
        }
        return total;
    }
}

class Option {
    String label;
    boolean isCategory;
    Object item;
    boolean isVisible = true;
    boolean isExpanded = true;

    Option(String _label) {
        label = _label;
        isCategory = true;
    }
    
    Option(String _label, Object _item) {
        label = _label;
        item = _item;
        isCategory = false;
    }

    void display(float x, float y, float w, float h) {
        menuG.fill(isCategory ? 180 : 255); // Differentiate category color
        menuG.rect(x, y, w, h);
        menuG.fill(0);
        menuG.textSize(10);
        menuG.text(label, x + 10, y + h / 2 + 5);
        if (isCategory) {
            menuG.text(isExpanded ? "-" : "+", x + w - 15, y + h / 2 + 5);
        }
    }

    boolean isCategory() {
        return isCategory;
    }

    void toggle() {
        isExpanded = !isExpanded;
        int index = selectedCity.getProductionIndex(this) + 1;
        while (index < selectedCity.getProductionOptionsCount() && !selectedCity.isProductionOptionCategory(index)) {
            productionMenu.options.get(index).isVisible = isExpanded;
            index++;
        }
    }
}