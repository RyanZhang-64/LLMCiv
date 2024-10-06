import java.util.function.Consumer;

class BoardClickHandler {
    private float xRadius = hexRadius;
    private float yRadius = hexRadius*0.8;
  
    public boolean citySelector(AxialCoord coord) {
        if (selectedCity != null && selectedCity.isBombarding()) {
            if (board.getCityAtCoord(coord) == selectedCity) {
                selectedCity.cancelBombard();
            } else {
                Unit enemy = board.getFrontUnitAtCoord(coord);
                if (enemies.contains(enemy)) {
                    selectedCity.bombard(enemy);
                }
            }
        } else {
            float mx = (mouseX - offsetX) / zoomFactor;
            float my = (mouseY - offsetY) / zoomFactor - hexRadius/2;
            
            City clickedCity = null;
            for (City city : board.getCityMapCities()) {
                float markerYOffset = city.isMarkerOffset() ? hexRadius : 0; // If marker is offset, adjust the Y position
                float startY = city.getY() + negOffsetY - hexRadius/2 - markerYOffset;
                float endY = startY + hexRadius;
                
                if (mx >= city.getX() + negOffsetX - 80*hexRadius/30 && mx <= city.getX() + negOffsetX + 80*hexRadius/30 && my >= startY && my <= endY) {
                    if (city.getCiv() == thisCiv) {
                        clickedCity = city;
                        break;
                    }
                }
            }
            if (clickedCity == null || clickedCity.getCiv() != thisCiv) return false;
        
            if (selectedCity == null) {
                if (clickedCity.isUnitAtCityCenter()) {
                    if (!clickedCity.isMarkerOffset()) {
                        clickedCity.setMarkerOffset(true); // Move the marker up to reveal the unit
                    } else {
                        // Marker is already offset, now open the city menu and apply mask
                        selectCity(clickedCity);
                    }
                } else {
                    selectCity(clickedCity);
                }
            } else if (selectedCity == clickedCity) {
                if (clickedCity.isMarkerOffset()) {
                    clickedCity.setMarkerOffset(false); // Move the marker back down if it was offset
                }
                deselectCity();
            }
        }
        return true;
    }
    
    public void unitSelector(AxialCoord coord) {
        if (selectedUnit == null || selectedUnit.getType() == UnitType.TRADER) {
            if (thisCiv.isSecondaryUnitAtCoord(coord)) {
                float mx = (mouseX - offsetX) / zoomFactor - negOffsetX;
                float my = (mouseY - offsetY) / zoomFactor - negOffsetY;

                int i = 0;
                for (PVector pos : thisCiv.getSecondaryUnitHitboxes(coord)) {
                    if (dist(mx, my, pos.x, pos.y) < hexRadius/4) {
                        thisCiv.bringUnitToFront(coord, i);
                        return;
                    }
                    i++;
                }
            }
            Unit unit = board.getFrontUnitAtCoord(coord);
            if (unit != null) {
                if (unit.getCiv() != thisCiv) {
                    unit = null;
                }
                if (unit != null) {
                    unit.select();
                }
            } else {
                float mx = (mouseX - offsetX) / zoomFactor - negOffsetX;
                float my = (mouseY - offsetY) / zoomFactor - negOffsetY;

                for (Map.Entry<PVector, City> entry : thisCiv.getCityBombardHitboxes().entrySet()) {
                    if (!entry.getValue().hasBombarded() && dist(mx, my, entry.getKey().x, entry.getKey().y) < hexRadius/2) {
                        entry.getValue().showBombard();
                        return;
                    }
                }
            }
        } else if (selectedUnit.getType() != UnitType.TRADER) {
            City clickedCity = board.getCityAtCoord(coord);
            if (validMoves.containsKey(coord)) {
                if (!coord.equals(selectedUnit.getHex())) {
                    if (clickedCity == null || thisCiv.getRelationship(clickedCity.getCiv()).isFriendly()) {
                        if (board.isUnitMultiMove(selectedUnit)) {
                            board.removeUnitToMultiMove(selectedUnit);
                        }
                        selectedUnit.move(coord, validMoves.get(coord));
                    }
                } else {
                    selectedUnit.deselect();
                }
            } else {
                if (enemyCities.contains(clickedCity)) {
                    selectedUnit.siege(clickedCity);
                } else {
                    Unit enemy = board.getFrontUnitAtCoord(coord);
                    if (enemies.contains(enemy)) {
                        selectedUnit.attack(enemy);
                    } else {
                        if (embarkCoords.contains(coord)) {
                            selectedUnit.embark(coord);
                        } else if (board.isCoordAccessible(coord, selectedUnit.isLand(), true)) {
                            board.addUnitToMultiMove(selectedUnit, coord);
                            selectedUnit.multiMove(coord);
                            if (selectedUnit != null) {
                                selectedUnit.deselect();
                            }
                        }
                    }
                }
            }
        }
    }
    
    private void selectCity(City city) {
        snapCamera(city.getX(), city.getY());
        gui.hide(GUIType.NEXTTURN);
        city.drawMask();
        cityDarkG.beginDraw();
        cityDarkG.background(#000032);
        cityDarkG.endDraw();
        cityDarkG.mask(cityMaskG);
        selectedCity = city;
        selectedCity.updateProductionOptions();
        productionMenu = new ProductionMenu(selectedCity.getProductionOptions(), 50, 50, 200, 200, 300);
        board.setState(State.PRODUCTION);
        productionMenu.drawOptions();
    }
    
    private void deselectCity() {
        cityDarkG.beginDraw();
        gui.show(GUIType.NEXTTURN, true);
        cityDarkG.clear();
        cityDarkG.endDraw();
        selectedCity = null;
        menuG.beginDraw();
        menuG.clear();
        menuG.endDraw();
        productionMenu = null;
        board.setState(State.GAME);
    }
}
