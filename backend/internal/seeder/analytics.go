package seeder

import "time"

func SeedKinoTicketTransactions(now time.Time) []KinoTicketTransactionSeed {
	base := now.UTC()
	return []KinoTicketTransactionSeed{
		{
			TransactionID:    1001,
			UserID:           501,
			PurchaseDatetime: base.Add(-72 * time.Hour),
			EventDatetime:    base.Add(48 * time.Hour),
			EventID:          9001,
			EventName:        "Family Movie Night",
			ClassCode:        "movie",
			SubclassCode:     "family_movie",
			GenreCode:        "animation",
			City:             "Almaty",
			VenueName:        "Kino.kz Mock Hall",
			TicketsCount:     4,
			TicketPrice:      4500,
			TotalAmount:      18000,
			PaymentMethod:    "halyk_card",
			BonusUsed:        0,
			CashbackAmount:   900,
			SourcePlatform:   "halyk_app",
			Status:           "paid",
		},
		{
			TransactionID:    1002,
			UserID:           777,
			PurchaseDatetime: base.Add(-24 * time.Hour),
			EventDatetime:    base.Add(72 * time.Hour),
			EventID:          9002,
			EventName:        "Live Concert Pick",
			ClassCode:        "concert",
			SubclassCode:     "live_concert",
			GenreCode:        "",
			City:             "Berlin",
			VenueName:        "Partner Arena",
			TicketsCount:     1,
			TicketPrice:      22000,
			TotalAmount:      22000,
			PaymentMethod:    "halyk_card",
			BonusUsed:        0,
			CashbackAmount:   1100,
			SourcePlatform:   "kino_kz_app",
			Status:           "paid",
		},
	}
}

func SeedAccountTransactions(now time.Time) []AccountTransactionSeed {
	base := now.UTC()
	return []AccountTransactionSeed{
		{
			TransactionID:       2001,
			UserID:              501,
			AccountID:           3001,
			AccountType:         "card",
			TransactionDatetime: base.Add(-96 * time.Hour),
			TransactionType:     "card_payment",
			Direction:           "expense",
			Amount:              95000,
			Currency:            "KZT",
			BalanceBefore:       1200000,
			BalanceAfter:        1105000,
			CounterpartyName:    "Family View Almaty",
			CategoryCode:        "travel_hotel",
			CategoryName:        "Hotel",
			Channel:             "online_payment",
			Description:         "Mock hotel booking payment",
			Status:              "success",
		},
		{
			TransactionID:       2002,
			UserID:              777,
			AccountID:           3002,
			AccountType:         "card",
			TransactionDatetime: base.Add(-48 * time.Hour),
			TransactionType:     "card_payment",
			Direction:           "expense",
			Amount:              245000,
			Currency:            "KZT",
			BalanceBefore:       980000,
			BalanceAfter:        735000,
			CounterpartyName:    "Lufthansa Mock",
			CategoryCode:        "travel_transport",
			CategoryName:        "Transport",
			Channel:             "mobile_app",
			Description:         "Mock international flight purchase",
			Status:              "success",
		},
	}
}
