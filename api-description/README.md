# Описание эндпоинтов мессенджера

## Навигация по эндпоинтам

| **Эндпоинт**                            | **Описание**                         | **Документация**                                 |
|-----------------------------------------|--------------------------------------|--------------------------------------------------|
| `POST /c/{conversationId}/send`         | Отправить сообщение                  | [Подробнее](general/send-message/)               |
| `GET /group-chat/{conversationId}/info` | Получить информацию о групповом чате | [Подробнее](group-chats/get-group-chat-info/)    |
| `PUT /group-chat/{conversationId}/info` | Изменить информацию о групповом чате | [Подробнее](group-chats/change-group-chat-info/) |
| `POST /channel/create`                  | Создать канал                        | [Подробнее](channels/create-channel/)            |
| `POST /channel/{conversationId}/join`   | Присоединиться к каналу              | [Подробнее](channels/join-channel/)              |
