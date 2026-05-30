# Smart Trip Map and Personalization

## Smart Trip Map

The selected trip screen should not be just a list. It should be a ready interactive travel map.

The map shows:
- arrival airport or station;
- selected hotel;
- attractions;
- events;
- restaurants;
- districts;
- routes;
- estimated time and movement cost.

## Airport to hotel logic

If the airport is far from the hotel, show:
- distance;
- travel time;
- taxi estimate;
- public transport alternative;
- shuttle/rental car alternative if relevant;
- warning if transfer noticeably increases budget.

Example labels:
- `Airport is far: taxi to hotel ≈ 9 000 ₸, 45 min.`
- `Save money: public transport ≈ 900 ₸, 70 min.`

## Hotel positioning logic

Hotel is selected not only by price and rating, but by position relative to the plan.

The system can suggest:
- closer to route: more expensive, less travel time;
- balanced: normal price and acceptable distance;
- cheaper but farther: saves hotel cost, increases transport cost.

## Global trip style switch

One global switch controls the whole plan.

### Economy

- hotel farther from center;
- cheaper room;
- more public transport;
- fewer paid events;
- show savings.

### Balanced

- convenient district;
- reasonable price;
- mixed transport;
- optimal route without overload.

### Comfort

- hotel closer to objects;
- better room;
- fewer transfers;
- more taxi/direct routes;
- higher cost, less fatigue.

## Invisible AI value

AI should not look like a separate layer. It quietly:
- changes hotel;
- changes selected room;
- recalculates transport cost;
- sorts objects;
- shows trade-off between price and comfort;
- explains each choice with short labels.

Example labels:
- `This hotel costs 18% more, but saves around 2 hours of travel.`
- `This room is cheaper by 20 000 ₸, but breakfast is not included.`
- `This option saves 21 000 ₸, but most places will be farther away.`
- `The route is overloaded: 6 places in one day. Remove 1–2.`

## Personalization

AI uses:
- transaction categories;
- previous travel countries;
- travel seasonality;
- average travel budget;
- spending level;
- hotel preference;
- event/restaurants/categories;
- visa constraints;
- cashback partner availability.

User sees:
- `Fits you because...`
- `Cheapest option`
- `More expensive, but direct flight`
- `More events near the hotel`
- `Visa-free for your citizenship`
- `Get up to X ₸ cashback`
