# Hotel Reviews and Room Selection

Hotel is a key decision block. It should not be only `name + price`.

## API should provide

For each hotel:
- base information;
- coordinates;
- hotel rating;
- source ratings;
- reviews grouped by source;
- short summarized review;
- available rooms;
- selected room;
- upgrade/downgrade options;
- reason why this hotel and room were selected.

## Hotel object

```json
{
  "hotelId": "hotel_001",
  "name": "Four Seasons Hotel Amman",
  "city": "Amman",
  "district": "5th Circle",
  "address": "5th Circle, Amman, Jordan",
  "lat": 31.9454,
  "lng": 35.8802,
  "stars": 5,
  "mainImageUrl": "https://example.com/hotel.jpg",
  "rating": {
    "overall": 9.1,
    "scale": 10,
    "label": "Excellent",
    "reviewCount": 1842
  },
  "sourceRatings": [],
  "reviewSummary": {},
  "reviewsBySource": [],
  "rooms": [],
  "selectedRoomId": "room_balanced_001",
  "roomOptions": {},
  "locationInfo": {},
  "reason": "Дороже среднего, но ближе к вечерним местам и экономит время на перемещениях."
}
```

## Source ratings

```json
[
  {
    "source": "Booking.com",
    "rating": 9.1,
    "scale": 10,
    "reviewCount": 1240,
    "url": "https://example.com"
  },
  {
    "source": "Google Hotels",
    "rating": 4.6,
    "scale": 5,
    "reviewCount": 5300,
    "url": "https://example.com"
  },
  {
    "source": "Tripadvisor",
    "rating": 4.5,
    "scale": 5,
    "reviewCount": 2100,
    "url": "https://example.com"
  }
]
```

## Reviews grouped by source

UI can show tabs/sections:
- Booking.com;
- Google Hotels;
- Tripadvisor;
- Expedia/Agoda/local provider.

```json
{
  "source": "Booking.com",
  "totalReviews": 1240,
  "averageRating": 9.1,
  "scale": 10,
  "reviews": [
    {
      "reviewId": "booking_rev_001",
      "authorName": "Aigerim",
      "rating": 9.0,
      "scale": 10,
      "date": "2026-04-12",
      "language": "ru",
      "title": "Удобное расположение и отличный сервис",
      "text": "Отель удобно расположен, персонал помог с трансфером, номер был чистый.",
      "pros": ["location", "service", "cleanliness"],
      "cons": ["expensive_breakfast"]
    }
  ]
}
```

## Summarized hotel review

API should provide a short summary, so frontend does not summarize reviews itself.

```json
{
  "shortSummary": "Гости чаще всего хвалят сервис, чистоту и удобное расположение. Главные минусы — высокая цена завтрака и иногда шумные номера возле дороги.",
  "positivePoints": [
    "Хороший сервис",
    "Чистые номера",
    "Удобное расположение",
    "Комфортные кровати"
  ],
  "negativePoints": [
    "Дорогой завтрак",
    "Некоторые номера шумные",
    "Высокая цена в сезон"
  ],
  "bestFor": ["couples", "comfort_travel", "business", "first_time_city_visit"],
  "notIdealFor": ["strict_budget", "party_area_seekers"],
  "confidence": "medium",
  "basedOnSources": ["Booking.com", "Google Hotels", "Tripadvisor"]
}
```

## Rooms

```json
[
  {
    "roomId": "room_economy_001",
    "name": "Superior Room",
    "description": "Базовый номер с king bed и видом на город.",
    "imageUrl": "https://example.com/room.jpg",
    "capacity": 2,
    "bedType": "king",
    "areaSqm": 32,
    "refundable": true,
    "breakfastIncluded": false,
    "pricePerNight": {
      "amount": 52000,
      "currency": "KZT"
    },
    "totalPrice": {
      "amount": 104000,
      "currency": "KZT"
    },
    "labels": ["Дешевле", "Без завтрака"],
    "tradeoffLabel": "Дешевле на 20 000 ₸, но без завтрака и с меньшей площадью."
  },
  {
    "roomId": "room_balanced_001",
    "name": "Deluxe Room",
    "description": "Более просторный номер с лучшим видом и завтраком.",
    "imageUrl": "https://example.com/room.jpg",
    "capacity": 2,
    "bedType": "king",
    "areaSqm": 40,
    "refundable": true,
    "breakfastIncluded": true,
    "pricePerNight": {
      "amount": 62000,
      "currency": "KZT"
    },
    "totalPrice": {
      "amount": 124000,
      "currency": "KZT"
    },
    "labels": ["Выбрано для вас", "Завтрак включён", "Лучший баланс"],
    "tradeoffLabel": "Лучший баланс цены, завтрака и комфорта."
  },
  {
    "roomId": "room_comfort_001",
    "name": "Executive Suite",
    "description": "Большой номер с lounge access и лучшим видом.",
    "imageUrl": "https://example.com/room.jpg",
    "capacity": 2,
    "bedType": "king",
    "areaSqm": 58,
    "refundable": true,
    "breakfastIncluded": true,
    "pricePerNight": {
      "amount": 89000,
      "currency": "KZT"
    },
    "totalPrice": {
      "amount": 178000,
      "currency": "KZT"
    },
    "labels": ["Апгрейд", "Больше места", "Лучший вид"],
    "tradeoffLabel": "Дороже на 54 000 ₸, но больше места и лучше вид."
  }
]
```

## Upgrade and downgrade options

```json
{
  "selectedRoomId": "room_balanced_001",
  "downgradeRoomId": "room_economy_001",
  "upgradeRoomId": "room_comfort_001",
  "selectedReason": "Этот номер выбран как лучший баланс: завтрак включён, больше площадь и нормальная цена.",
  "downgradeLabel": "Сэкономить 20 000 ₸, но без завтрака",
  "upgradeLabel": "Добавить 54 000 ₸ за suite и лучший вид"
}
```

## Hotel location info

```json
{
  "distanceToAirportKm": 36.4,
  "taxiFromAirport": {
    "amount": 9000,
    "currency": "KZT"
  },
  "distanceToMainClusterKm": 2.4,
  "averageTaxiToActivities": {
    "amount": 1800,
    "currency": "KZT"
  },
  "walkablePlacesCount": 4,
  "locationScore": 0.88,
  "priceScore": 0.62,
  "convenienceScore": 0.82
}
```

## Hotel segment compact data

```json
{
  "segmentId": "seg_hotel_001",
  "type": "check_in",
  "title": "Check-in: Four Seasons Hotel Amman",
  "labels": ["9.1 Excellent", "Выбран Deluxe Room", "Завтрак включён"],
  "details": {
    "hotelId": "hotel_001",
    "selectedRoomId": "room_balanced_001",
    "ratingLabel": "9.1 Excellent",
    "reviewShortSummary": "Гости хвалят сервис, чистоту и расположение. Минусы — дорогой завтрак и шум у дороги.",
    "downgradeLabel": "Сэкономить 20 000 ₸",
    "upgradeLabel": "Апгрейд за +54 000 ₸"
  }
}
```

## Hackathon scope

Must-have:
- 2–3 rating sources;
- 3–5 reviews per source;
- summarized review;
- 3 room options per hotel.

Nice-to-have:
- real reviews provider;
- real-time room availability;
- review sentiment analysis;
- review translation;
- trust score showing whether sources agree.
