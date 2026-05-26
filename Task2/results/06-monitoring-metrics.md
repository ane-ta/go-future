# ADR-\_: Метрики мониторинга

## Контекст

Система GoFuture переходит на микросервисную архитектуру с тремя географическими регионами (Asia, South America, Europe).

Требования к мониторингу:

- Обеспечить 99.99% доступности критических сервисов
- Сократить MTTR (среднее время восстановления) с 4+ часов до 15 минут
- Предоставить SRE и разработчикам информацию о состоянии системы
- Предоставить бизнес-аналитикам метрики для принятия решений

## Проблема

Выбрать метрики мониторинга для предотвращения и оперативной реакции на инциденты.

## Решение

### Технические метрики:

|  |  |  |  |
|----|----|----|----|
| Метрика | Что измеряет | Порог | Действие |
| ————————- | ————————– | ————– | ———————————- |
| \`event<sub>lag</sub>\` | Задержка обработки события | \> 5 сек | Увеличить consumer'ов |
| \`consumer<sub>lag</sub>\` | Накопление сообщений | \> 1000 | Увеличить партиции или consumer'ов |
| \`dead<sub>letter</sub>\_queue<sub>size</sub>\` | Необработанные события | \> 100 | Алерт инженерам |
| \`event<sub>processing</sub>\_errors\` | Ошибки обработки | \> 1% за минуту | Проверить схему данных |
| \`saga<sub>duration</sub>\` | Длительность саги | \> 30 сек | Оптимизировать шаги |
| \`saga<sub>failures</sub>\` | Отменённые заказы | \> 5% за час | Алерт, анализ причин |
| \`outbox<sub>lag</sub>\` | Задержка CDC | \> 1 сек | Проверить Debezium |
| \`service<sub>up</sub>\` | Доступность сервиса | 0 (down) | PagerDuty |

****Автоматические метрики (бесплатно для всех сервисов):****

| Метрика | Что измеряет | Тип |
|----|----|----|
| \`process<sub>cpu</sub>\_seconds<sub>total</sub>\` | CPU время процесса (суммарно) | Counter |
| \`process<sub>resident</sub>\_memory<sub>bytes</sub>\` | Память процесса (RSS) | Gauge |
| \`process<sub>virtual</sub>\_memory<sub>bytes</sub>\` | Виртуальная память | Gauge |
| \`process<sub>open</sub>\_fds\` | Открытые файловые дескрипторы | Gauge |
| \`process<sub>max</sub>\_fds\` | Максимум открытых FD | Gauge |
| \`python<sub>gc</sub>\_*\` | Сборщик мусора (объекты, время) | Counter / Gauge |
| \`python<sub>info</sub>\` | Версия Python и среда | Gauge (константа) |

### Бизнес-метрики (добавляются в код):

|  |  |  |  |
|----|----|----|----|
| Сервис | Метрика | Тип | Назначение |
| ———————— | ———————————- | ——— | ———————————- |
| ****Booking Service**** | \`bookings<sub>created</sub>\_total\` | Counter | Количество созданных заказов |
|  | \`bookings<sub>cancelled</sub>\_total\` | Counter | Количество отменённых заказов |
| ****Orchestrator**** | \`saga<sub>duration</sub>\_seconds\` | Histogram | Длительность саги (регион, статус) |
|  | \`saga<sub>total</sub>\` | Counter | Количество саг (регион, статус) |
|  | \`active<sub>sagas</sub>\` | Gauge | Активные саги (регион) |
| ****Driver Service**** | \`drivers<sub>assigned</sub>\_total\` | Counter | Назначенные водители |
|  | \`driver<sub>search</sub>\_duration<sub>seconds</sub>\` | Histogram | Время поиска водителя |
|  | \`driver<sub>proposals</sub>\_total\` | Counter | Отправленные предложения |
|  | \`driver<sub>accepted</sub>\_total\` | Counter | Принятые предложения |
|  | \`driver<sub>rejected</sub>\_total\` | Counter | Отклонённые предложения |
| ****Payments Service**** | \`payments<sub>hold</sub>\_total\` | Counter | Холды платежей |
|  | \`payments<sub>release</sub>\_total\` | Counter | Релизы платежей |
|  | \`payments<sub>charge</sub>\_total\` | Counter | Финальные списания |
|  | \`payments<sub>errors</sub>\_total\` | Counter | Ошибки платежей (по типу) |
|  | \`payments<sub>hold</sub>\_duration<sub>seconds</sub>\` | Histogram | Длительность холда |
| ****Geo Service**** | \`geo<sub>search</sub>\_total\` | Counter | Геозапросы |
|  | \`geo<sub>search</sub>\_duration<sub>seconds</sub>\` | Histogram | Длительность поиска |
|  | \`geo<sub>errors</sub>\_total\` | Counter | Ошибки Elasticsearch / Яндекс.Карт |
| ****Fraud Service**** | \`fraud<sub>checks</sub>\_total\` | Counter | Проверки на фрод |
|  | \`fraud<sub>alerts</sub>\_total\` | Counter | Обнаруженные фрод-инциденты |
| ****Notification Service**** | \`notifications<sub>sent</sub>\_total\` | Counter | Отправленные уведомления (по типу) |
|  | \`notifications<sub>errors</sub>\_total\` | Counter | Ошибки отправки |
| ****Payouts Service**** | \`payouts<sub>completed</sub>\_total\` | Counter | Выплаты водителям |
|  | \`payouts<sub>errors</sub>\_total\` | Counter | Ошибки выплат |
| ****Analytics Service**** | \`analytics<sub>events</sub>\_processed<sub>total</sub>\` | Counter | Обработанные аналитические события |
|  | \`analytics<sub>lag</sub>\_seconds\` | Gauge | Задержка обработки аналитики |

****Как это работает:****

1.  Каждый сервис подключает библиотеку `prometheus_client`
2.  Сервис запускает HTTP-сервер (порт 8000) с эндпоинтом `/metrics`
3.  Автоматические метрики появляются без дополнительного кода
4.  Бизнес-метрики добавляются в код в ключевых местах
5.  Grafana Alloy скрапит `/metrics` (pull) или сервис пушит через Alloy
6.  Метрики доступны в PromQL для дашбордов и алертов в Grafana

## Ограничения и риски

| Риск | Вероятность | Смягчение |
|----|----|----|
| ****Слишком много метрик**** | Средняя | Использовать гистограммы с ограниченными bucket'ами, агрегировать на стороне Prometheus |
| ****Высокая нагрузка на сервисы из-за сбора метрик**** | Низкая | Метрики собираются в отдельном потоке, не блокируют основной |
| ****Метрики не отражают реальную картину**** | Средняя | Регулярный аудит метрик с бизнес-командой |
| ****Хранение исторических метрик**** | Средняя | Retention в Prometheus: 30 дней (технические), 90 дней (агрегированные) |
| ****Разные версии метрик в разных сервисах**** | Низкая | Стандартизация через общую библиотеку метрик |
