import java.util.Objects;

class AxialCoord {
    private final int q; // Axial coordinate
    private final int r; // Axial coordinate

    public AxialCoord(int _q, int _r) {
        q = _q;
        r = _r;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        AxialCoord that = (AxialCoord) o;
        return q == that.q && r == that.r;
    }

    public boolean equals(int _q, int _r) {
        return q == _q && r == _r;
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(q, r);
    }
    
    public int getQ() {return q;}
    public int getR() {return r;}
    public String toString() {return str(q) + " " + str(r);}
    
    // Error on calling dist(), since coord seems to be empty?

    public int dist(AxialCoord coord) {
        int x2 = coord.getQ();
        int z2 = coord.getR();
        int y1 = -q-r;
        int y2 = -x2-z2;
        return max(max(abs(x2 - q), abs(y2 - y1)), abs(z2 - r));
    }
}

class CubeCoord {
    private final float q;
    private final float r;
    private final float s;

    public CubeCoord(float _q, float _r, float _s) {
        q = _q;
        r = _r;
        s = _s;
    }

    public float getQ() {return q;}
    public float getR() {return r;}
    public float getS() {return s;}
}

class HexEdge {
    private float startX, startY, endX, endY;
    private int comparerStartY, comparerEndY;

    public HexEdge(float _startX, float _startY, float _endX, float _endY) {
        startX = _startX;
        startY = _startY;
        endX = _endX;
        endY = _endY;
        comparerStartY = (int) startY;
        comparerEndY = (int) endY;
    }
    
    public HexEdge getOffset(float _offsetX, float _offsetY) {
        float offsetStartX = startX + _offsetX;
        float offsetStartY = startY + _offsetY;
        float offsetEndX = endX + _offsetX;
        float offsetEndY = endY + _offsetY;
    
        // Create a new HexEdge with updated offsets
        HexEdge newEdge = new HexEdge(offsetStartX, offsetStartY, offsetEndX, offsetEndY);
    
        // Update comparer values
        newEdge.comparerStartY = (int) offsetStartY;
        newEdge.comparerEndY = (int) offsetEndY;
    
        return newEdge;
    }


    public float getStartX() { return startX; }
    public float getStartY() { return startY; }
    public float getEndX() { return endX; }
    public float getEndY() { return endY; }

    public int getComparerStartY() { return comparerStartY; }
    public int getComparerEndY() { return comparerEndY; }

    public PVector getStartCoord() {
        return new PVector(startX, comparerStartY);
    }
    
    public PVector getEndCoord() {
        return new PVector(endX, comparerEndY);
    }
}

import java.util.Objects;
import java.util.Comparator;

public class TerrainTile {
    private AxialCoord coord;
    private float elevation;
    private Biome biome;

    public TerrainTile(AxialCoord coord, float elevation, Biome biome) {
        this.coord = coord;
        this.elevation = elevation;
        this.biome = biome;
    }

    public AxialCoord getCoord() {return coord;}
    public float getElevation() {return elevation;}
    public Biome getBiome() {return biome;}

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        TerrainTile that = (TerrainTile) o;
        return Float.compare(that.elevation, elevation) == 0 &&
               Objects.equals(coord, that.coord) &&
               biome == that.biome;
    }

    @Override
    public int hashCode() {
        return Objects.hash(coord, elevation, biome);
    }

    @Override
    public String toString() {
        return "TerrainTile{" +
               "coord=" + coord +
               ", elevation=" + elevation +
               ", biome=" + biome +
               '}';
    }
}

public class ElevationComparator implements Comparator<TerrainTile> {
    @Override
    public int compare(TerrainTile t1, TerrainTile t2) {
        return Float.compare(t1.getElevation(), t2.getElevation());
    }
}

public class Pair<K, V> {
    private K key;
    private V value;

    // Constructor to initialize the pair
    public Pair(K key, V value) {
        this.key = key;
        this.value = value;
    }

    public K getKey() {return key;}
    public void setKey(K _key) {key = _key;}
    public V getValue() {return value;}
    public void setValue(V _value) {value = _value;}

    // Equals method to compare two Pair objects
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        Pair<?, ?> pair = (Pair<?, ?>) o;

        if (key != null ? !key.equals(pair.key) : pair.key != null) return false;
        return value != null ? value.equals(pair.value) : pair.value == null;
    }

    // HashCode method to generate hash code
    @Override
    public int hashCode() {
        int result = key != null ? key.hashCode() : 0;
        result = 31 * result + (value != null ? value.hashCode() : 0);
        return result;
    }

    // ToString method to return string representation of the pair
    @Override
    public String toString() {
        return "Pair{" +
                "key=" + key +
                ", value=" + value +
                '}';
    }
}
