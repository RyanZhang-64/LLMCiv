class BiomeRule {
    private float minElevation, maxElevation;
    private float minMoisture, maxMoisture;
    private float minTemperature, maxTemperature;
    private Biome biome;

    public BiomeRule(float _minElevation, float _maxElevation, float _minMoisture, float _maxMoisture, float _minTemperature, float _maxTemperature, Biome _biome) {
        minElevation = _minElevation;
        maxElevation = _maxElevation;
        minMoisture = _minMoisture;
        maxMoisture = _maxMoisture;
        minTemperature = _minTemperature;
        maxTemperature = _maxTemperature;
        biome = _biome;
    }

    public boolean matches(float elevation, float moisture, float temperature) {
        return elevation >= minElevation && elevation <= maxElevation &&
               moisture >= minMoisture && moisture <= maxMoisture &&
               temperature >= minTemperature && temperature <= maxTemperature;
    }
}

class TerrainTileRule {
    private float minElevation, maxElevation;
    private float minMoisture, maxMoisture;
    private TileType type;

    public TerrainTileRule(float _minElevation, float _maxElevation, float _minMoisture, float _maxMoisture, TileType _type) {
        minElevation = _minElevation;
        maxElevation = _maxElevation;
        minMoisture = _minMoisture;
        maxMoisture = _maxMoisture;
        type = _type;
    }
    
    public TileType getType() {return type;}

    public boolean matches(float elevation, float moisture) {
        return elevation >= minElevation && elevation <= maxElevation &&
               moisture >= minMoisture && moisture <= maxMoisture;
    }
}
