package trip

type destinationReference struct {
	CountryCode        string
	CountryName        string
	CityName           string
	CityRegion         string
	CityDescription    string
	Attractions        []referenceAttraction
	Restaurants        []referenceRestaurant
	Events             []referenceEvent
	FoodEstimate       int
	LocalTransportCost int
	InsuranceEstimate  int
}

type referenceAttraction struct {
	Name        string `db:"name_en"`
	Category    string `db:"category"`
	Description string `db:"description"`
	DurationMin int    `db:"recommended_duration_minutes"`
	PriceLevel  string `db:"price_level"`
}

type referenceRestaurant struct {
	Name        string `db:"name"`
	Cuisine     string `db:"cuisine"`
	PriceLevel  string `db:"price_level"`
	Description string `db:"description"`
	Area        string `db:"area"`
}

type referenceEvent struct {
	Name        string `db:"name_en"`
	Category    string `db:"category"`
	Description string `db:"description"`
	TravelTip   string `db:"travel_tip"`
}

type countryRow struct {
	CountryCode string `db:"country_code"`
	NameEn      string `db:"name_en"`
}

type cityRow struct {
	CityID      int    `db:"city_id"`
	CountryCode string `db:"country_code"`
	NameEn      string `db:"name_en"`
	Region      string `db:"region"`
	Description string `db:"description"`
}
