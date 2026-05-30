## Halyk Travel Hackathon Hub

**Halyk Travel** — smart travel planner inside Halyk ecosystem: готовые поездки, карта, timeline, бюджет, визы, персонализация, кешбэк и financial challenges.

## Navigation

01 Product Overview

02 UX Flow and Segmented Trip Plan

03 Smart Trip Map and Personalization

04 API Data Requirements

05 API Response Classes and Models

06 Development Stages and Tasks

07 Original Notes Archive

## Current product direction

Главная форма продукта: **segmented trip timeline + smart map**.

Пользователь получает не просто список рекомендаций, а готовый план:

1. Arrival
2. Transfer airport → hotel
3. Check-in / hotel
4. Day itinerary
5. Intercity movement
6. Departure

Карта синхронизирована с timeline: tap по сегменту фокусирует карту, tap по marker скроллит timeline.

## Key demo moment

Пользователь переключает режим:

- **Экономнее** — дешевле, но дальше и больше времени в пути.
- **Сбалансировано** — оптимальный баланс цены и удобства.
- **Удобнее** — дороже, но ближе к объектам и меньше дороги.

После переключения меняются:

- отель;
- трансфер;
- транспортные расходы;
- travel time;
- total cost;
- карта и route labels.

## API focus

Backend/API должен отдавать frontend уже собранный `TripDetailsResponse`, а не просто сырые отели, рейсы и места.

Главные связи:

- `segmentId` связывает timeline, map markers, routes, warnings and smart labels.
- `markerId` нужен для карты.
- `routeId` нужен для маршрутов.
- `modeVariants` нужны для переключателя economy/balanced/comfort.

## Project tasks