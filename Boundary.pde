import java.util.Set;
import java.util.Deque;
import java.util.ArrayDeque;

class Boundary {
    private Set<AxialCoord> hexCoordinates;
    private ArrayList<PVector> vertices;
    private ArrayList<PVector> offsets;
    private PVector[] innerVertices;
    private PVector[] outerVertices;
    private HashMap<PVector, HexEdge> vertexEdgeMap;
    
    public Boundary(Set<AxialCoord> _hexCoordinates) {
        hexCoordinates = _hexCoordinates;
        vertices = new ArrayList<PVector>();
        offsets = new ArrayList<PVector>();
        vertexEdgeMap = new HashMap<PVector, HexEdge>();

        for (AxialCoord hex : hexCoordinates) {
            float[] offset = board.axialToCartesian(hex);
            for (AxialCoord dir : directions) {
                AxialCoord neighbour = new AxialCoord(hex.getQ() + dir.getQ(), hex.getR() + dir.getR());
                //println("Current", hex.getQ(), hex.getR(), "Neighbour", neighbour.getQ(), neighbour.getR(), hexCoordinates.contains(neighbour));
                if (!hexCoordinates.contains(neighbour)) {
                    HexEdge sharedEdge = sharedEdgeFromMove.get(dir);
                    HexEdge offsetEdge = sharedEdge.getOffset(offset[0], offset[1]);
                    //boundaryEdges.add(offsetEdge);
                    // When adding to vertexEdgeMap
                    vertexEdgeMap.put(new PVector(offsetEdge.getStartX(), offsetEdge.getComparerStartY()), offsetEdge);
                }
            }
        }
        
        PVector startPoint = new PVector(vertexEdgeMap.keySet().iterator().next().x, (int) vertexEdgeMap.keySet().iterator().next().y);
        PVector currentPoint = new PVector(startPoint.x, startPoint.y);
        
        do {
            vertices.add(new PVector(currentPoint.x, currentPoint.y));  // use actual coordinates for vertices
            HexEdge nextEdge = vertexEdgeMap.get(new PVector(currentPoint.x, (int) currentPoint.y));
            if (nextEdge == null) {
                // Error handling or debugging output
                break;  // Prevent infinite loop in case of unmatched coordinates
            }
            currentPoint = nextEdge.getEndCoord();  // This now retrieves using comparer value
        } while (!currentPoint.equals(startPoint));

        
        outerVertices = new PVector[vertices.size()];
        innerVertices = new PVector[vertices.size()];
        
        for (int i = 0; i < vertices.size(); i++) {
            int nextIndex = (i + 1) % vertices.size();
            int prevIndex = (i - 1 + vertices.size()) % vertices.size();
            PVector nextEdge = PVector.sub(vertices.get(nextIndex), vertices.get(i));
            PVector prevEdge = PVector.sub(vertices.get(i), vertices.get(prevIndex));
            PVector normal = new PVector(-prevEdge.y-nextEdge.y, prevEdge.x+nextEdge.x);
            normal.normalize().mult((4*hexRadius/30)/2);
    
            outerVertices[i] = PVector.sub(vertices.get(i), normal);
            innerVertices[i] = PVector.add(vertices.get(i), normal);
        }
        
    }
    
    public void render(PGraphics pg, color outerStroke, color innerStroke, boolean isSelection) {
        pg.beginDraw();
        pg.strokeWeight(4*hexRadius/30);
        pg.translate(negOffsetX, negOffsetY);
        pg.noFill();
        
        pg.beginShape();
        pg.stroke(innerStroke, 200);
        for (PVector vertex : innerVertices) {
            pg.vertex(vertex.x, vertex.y);
        }
        pg.endShape(CLOSE);
        
        pg.beginShape();
        if (isSelection) {
            pg.stroke(outerStroke, 150);
        } else {
            pg.stroke(outerStroke);
        }
        for (PVector vertex : outerVertices) {
            pg.vertex(vertex.x, vertex.y);
        }
        pg.endShape(CLOSE);
        pg.endDraw();
    }
    
    public void renderInner(PGraphics pg, color innerStroke) {
        pg.beginDraw();
        pg.strokeWeight(4*hexRadius/30);
        pg.translate(negOffsetX, negOffsetY);
        pg.noFill();
        
        pg.beginShape();
        pg.stroke(innerStroke, 200);
        for (PVector vertex : innerVertices) {
            pg.vertex(vertex.x, vertex.y);
        }
        pg.endShape(CLOSE);
        pg.endDraw();
    }

    public void renderOuter(PGraphics pg, color outerStroke) {
        pg.beginDraw();
        pg.strokeWeight(4*hexRadius/30);
        pg.translate(negOffsetX, negOffsetY);
        pg.noFill();
        
        pg.beginShape();
        pg.stroke(outerStroke, 200);
        for (PVector vertex : outerVertices) {
            pg.vertex(vertex.x, vertex.y);
        }
        pg.endShape(CLOSE);
        pg.endDraw();
    }
}
