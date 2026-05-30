# Development Stages and Demo

## Stage 0 — Product framing

Goal: make the product easy to pitch.

Tasks:
- formulate problem;
- formulate value proposition;
- select hero demo flow;
- decide what is real and what is mocked;
- define 2–3 user personas.

Output:
- 1-page concept;
- demo script;
- MVP feature list.

## Stage 1 — Data and recommendation model

Goal: make simple explainable personalization.

Tasks:
- create mock transaction dataset;
- extract travel patterns;
- score destinations;
- generate reason labels;
- generate cashback/challenge options.

Output:
- recommendation function/notebook;
- recommendation JSON;
- personalization slide.

## Stage 2 — UX prototype

Goal: show the wow effect without a complex path.

Tasks:
- main recommendation screen;
- selected trip screen;
- segmented timeline;
- smart map;
- hotel card and room options;
- cost breakdown;
- cashback/challenge block.

Output:
- Figma or implemented mobile/web prototype.

## Stage 3 — Integrations layer

Goal: make architecture believable.

Tasks:
- weather API or mock;
- events API or mock;
- hotels provider or mock;
- flights provider or mock;
- visa mock database;
- bank profile/transactions mock.

Output:
- integration architecture diagram;
- API response examples.

## Stage 4 — MVP implementation

Goal: end-to-end demo.

Tasks:
- frontend screens;
- backend endpoints;
- mock data seed;
- trip details generation;
- hotel review/room data;
- cashback/challenge generation;
- error/empty states.

Output:
- working prototype URL/APK;
- GitHub README.

## Stage 5 — Pitch and polish

Goal: win with clarity.

Tasks:
- demo story;
- business model slide;
- risks slide;
- architecture slide;
- what is real / mocked / next.

Output:
- presentation;
- demo script;
- final checklist.

## Demo script

1. User opens Halyk Travel.
2. System knows user style: travels in summer, likes concerts, usually picks balanced budget.
3. Main screen shows trips: Istanbul, Tbilisi, Almaty weekend, Seoul seasonal, Jordan route.
4. User selects Jordan route.
5. Timeline and smart map appear.
6. System shows airport to hotel transfer and taxi/public transport comparison.
7. Hotel card shows rating, source reviews, summary and selected room.
8. User switches balanced → economy → comfort.
9. Hotel, room, route, travel time and total cost update.
10. User sees cashback/challenge.
11. Final message: Halyk helps travel more personally and profitably.

## Business model

- commission from travel partners;
- increased card usage through cashback;
- partner offers from events/places;
- premium travel perks for active users;
- retention inside banking app.

## Risks

- transaction data is sensitive: need consent and privacy.
- travel prices change quickly: show ranges and confidence.
- visa data may be inaccurate: use trusted source and disclaimer.
- AI recommendations may be wrong: user must edit route easily.
- some integrations can be mocked for hackathon, but architecture should look real.
