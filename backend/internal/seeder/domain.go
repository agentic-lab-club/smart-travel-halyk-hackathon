package seeder

import "time"

type DestinationSeed struct {
	City              string
	Country           string
	Transport         []TransportSeed
	Hotels            []HotelSeed
	Activities        []ActivitySeed
	Visa              VisaSeed
	Reviews           []ReviewSeed
	FoodEstimate      int
	LocalTransport    int
	InsuranceEstimate int
}

type TransportSeed struct {
	Mode        string
	Provider    string
	Title       string
	Origin      string
	Destination string
	Departure   string
	Arrival     string
	Price       int
	Currency    string
	Description string
}

type HotelSeed struct {
	Provider    string
	Name        string
	Location    string
	Price       int
	Currency    string
	Rating      float64
	Description string
	ReviewLink  string
}

type ActivitySeed struct {
	Kind        string
	Title       string
	Location    string
	DayLabel    string
	Price       int
	Currency    string
	SourceName  string
	SourceLink  string
	Description string
}

type VisaSeed struct {
	Country         string
	Requirement     string
	RecommendedLead string
	Checklist       []string
	Notes           string
}

type ReviewSeed struct {
	Kind       string
	TargetName string
	Summary    string
	SourceName string
	SourceLink string
}

type KinoTicketTransactionSeed struct {
	TransactionID    int64
	UserID           int64
	PurchaseDatetime time.Time
	EventDatetime    time.Time
	EventID          int64
	EventName        string
	ClassCode        string
	SubclassCode     string
	GenreCode        string
	City             string
	VenueName        string
	TicketsCount     int
	TicketPrice      float64
	TotalAmount      float64
	PaymentMethod    string
	BonusUsed        float64
	CashbackAmount   float64
	SourcePlatform   string
	Status           string
}

type AccountTransactionSeed struct {
	TransactionID       int64
	UserID              int64
	AccountID           int64
	AccountType         string
	TransactionDatetime time.Time
	TransactionType     string
	Direction           string
	Amount              float64
	Currency            string
	BalanceBefore       float64
	BalanceAfter        float64
	CounterpartyName    string
	CategoryCode        string
	CategoryName        string
	Channel             string
	Description         string
	Status              string
}
