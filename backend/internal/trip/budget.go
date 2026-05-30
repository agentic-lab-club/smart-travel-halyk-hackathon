package trip

func (s *Service) recalculateBudget(trip *Trip) {
	trip.BudgetSummary.TransportTotal = selectedTransportPrice(trip)
	trip.BudgetSummary.HotelTotal = selectedHotelPrice(trip)
	trip.BudgetSummary.EventsTotal = activitiesTotal(trip.Activities)
	trip.BudgetSummary.GrandTotal = trip.BudgetSummary.TransportTotal + trip.BudgetSummary.HotelTotal + trip.BudgetSummary.EventsTotal + trip.BudgetSummary.EstimatedFoodTotal + trip.BudgetSummary.EstimatedLocalTransport + trip.BudgetSummary.InsuranceEstimate
	trip.BudgetSummary.CashbackAmount = int(float64(trip.BudgetSummary.GrandTotal) * 0.05)
	trip.BudgetSummary.BonusAmount = int(float64(trip.BudgetSummary.GrandTotal) * 0.02)
	trip.BudgetSummary.HalykOfferLabel = "Pay fully with Halyk mock card and unlock cashback"
	trip.Offers = OfferSummary{
		CashbackAmount: trip.BudgetSummary.CashbackAmount,
		BonusAmount:    trip.BudgetSummary.BonusAmount,
		HalykOffer:     trip.BudgetSummary.HalykOfferLabel,
		Highlights:     []string{"Mock cashback applied on full Halyk payment", "Bonus estimate included for pitch and UI", "Kino.kz suggestions included where relevant"},
	}
}

func selectedTransportPrice(trip *Trip) int {
	if trip.SelectedTransport == nil {
		return 0
	}
	return trip.SelectedTransport.Price
}

func selectedHotelPrice(trip *Trip) int {
	if trip.SelectedHotel == nil {
		return 0
	}
	return trip.SelectedHotel.Price
}

func activitiesTotal(items []ActivityItem) int {
	total := 0
	for _, item := range items {
		total += item.Price
	}
	return total
}
