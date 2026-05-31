# smart-travel-halyk-hackathon

credentials: Agentic Lab IITU
team: Didar, Artem, Alexey, Yarik

Мы команда Agentic Lab, участвуем в Хакатоне от Halyk Banl Kazakhstan (superapp), этот репозиторий это наше решение и выбранный кейс, из списка [docs\Halyk_Кейсы_Хакатон.xlsx](docs\Halyk_Кейсы_Хакатон.xlsx), мы выбрали кейс: `9) Smart Travel Companion — Halyk Travel как центр управления поездкой`.
Это монорепозиторий.

## Architecture

> from [ARCHITECTURE.md](ARCHITECTURE.md)

C4-Diagram-Container-Diagram:

![C4-Diagram-Container-Diagram.png](/docs/assets/C4-Diagram-Container-Diagram.png)

---

Runtime Sequence:

![Runtime-Sequence.png](/docs/assets/Runtime-Sequence.png)

## Structure (обьеснение структуры папок)

> for important files/folders References descriptions check the [STRUCTURES.md](STRUCTURES.md)

## Наш выбранный Кейс

СТУДЕНЧЕСКИЙ ХАКАТОН — ДЕТАЛИ КЕЙСА:

---

| Поле | Значение |
| --- | --- |
| Кейс | 9) Smart Travel Companion — Halyk Travel как центр управления поездкой |
| AI-трек | Agentic AI / AI as UI |
| Описание и легенда | Halyk Travel воспринимается как сервис покупки билетов, но поездка не заканчивается билетом. Семья, Алматы–Астана на выходные: Halyk Travel создаёт Travel Plan автоматически — даты, билеты, состав семьи, чеклист, отель, трансфер, страховка, развлечения через Kino.kz, бюджет, бонус за оплату через Halyk. Путь: билет → Travel Plan → отель / трансфер / страховка / развлечения → оплата → бонус → следующая поездка. |
| Обязательные ограничения | Не нужен полноценный Booking.com — фокус на одном маршруте<br>Финансовая модель travel LTV семьи (обязательно)<br>Flywheel: каждый шаг ведёт к следующему без тупиков<br>Слайд с рисками и тем, что не успели |
| Критерии оценки | Транзакционная плотность: кол-во доп. оплат после покупки билета — 40%<br>Flywheel-логика без тупиков — 30%<br>Семейный сценарий: удобство планирования для всей семьи — 30% |
| Артефакт для сдачи | CJM (от билета до завершения поездки) + 5–7 экранов MVP + финансовая модель travel LTV + схема интеграций (авиа/жд, отели, страховка, трансфер, Kino.kz, Halyk payments, бонусная система) + презентация |

## Notes

