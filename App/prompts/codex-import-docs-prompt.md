# Codex Prompt: Add Halyk Travel Docs and AGENTS.md

You are working in the Halyk Travel hackathon project repository.

Your task is to add stable AI/developer documentation to the repo.

## Goal

Create a documentation structure under `docs/` and an `AGENTS.md` file at the repository root.

These docs are the source of truth for:
- product direction;
- UX flow;
- API contract;
- response models;
- mock data requirements;
- hotel reviews and room selection;
- demo flow.

## Files to create

Create this structure:

```txt
AGENTS.md
docs/
  README.md
  product/
    overview.md
    ux-flow-and-segmented-trip-plan.md
    smart-trip-map-and-personalization.md
  api/
    api-data-requirements.md
    api-response-models.md
  data/
    mock-data-requirements.md
    hotel-reviews-room-selection.md
  pitch/
    development-stages-and-demo.md
```

## Important requirements

1. Keep `AGENTS.md` short and actionable.
2. Do not make the agent instructions too broad or heavy.
3. Use `docs/api/api-response-models.md` as the API/model source of truth.
4. The backend should return a ready `TripDetailsResponse`, not raw disconnected hotel/flight/place data.
5. Timeline, map and warnings must be connected through stable IDs:
   - `segmentId`
   - `markerId`
   - `routeId`
6. Implement or mock data according to `docs/data/mock-data-requirements.md`.
7. Hotel data must include:
   - rating;
   - ratings by source;
   - reviews grouped by source;
   - summarized review;
   - selected room;
   - upgrade/downgrade options.

## After creating docs

1. Check whether the repo already has README conventions. If yes, add a short link to `docs/README.md`.
2. Do not overwrite existing docs unless they are clearly placeholders.
3. If there is an existing AGENTS.md, merge carefully instead of replacing.
4. Keep formatting clean and markdown-valid.

## Next implementation suggestion

After docs are added, implement:
- typed API models;
- mock trip dataset;
- trip details endpoint or local mock service;
- selected trip screen with segmented timeline and smart map.
