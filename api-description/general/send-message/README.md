# Описание эндпоинта `Отправить сообщение`

## 1. Протокол взаимодействия  

**HTTP/1.1 & REST**  

## 2. Метод запроса  

**POST**  

## 3. URL  

`/c/{conversationId}/send`  

## 4. Используемые заголовки  

- `Content-Type: application/json`  
- `Authorization: Bearer <токен>`  

## 5. Требования  

- ### 5.1. Аутентификация/Авторизация  

  - **Необходимость**: Обязательно.  
  - **Как работает**: Для выполнения запроса требуется передача валидного Bearer токена в заголовке `Authorization`.  

- ### 5.2. Кэширование  

  - **Необходимость**: Опционально.  
  - **Как работает**:  
    - На уровне обработки обращение к `Redis` для уменьшения запросов к БД. 

## 6. Структура запроса  

| **Параметр**     | **Передача** | **Обязательность** | **Тип данных** | **Описание**    | **Условия валидации**                   | **Значения по умолчанию / Допустимые значения** |
|----------------- |--------------|--------------------|----------------|-----------------|-----------------------------------------|-------------------------------------------------|
| `conversationId` | `path`       | Обязательный       | `string`       | Уникальный идентификатор чата | Должен быть валидным UUID | Нет значения по умолчанию                       |
| `content`        | `body`       | Необязательный     | `string`       | Текст сообщения | Длина должна быть от 1 до 3000 символов | Значение по умолчанию `null`                    |
| `attachments`    | `body`       | Необязательный     | `string[]`     | Файлы           | Должны быть валидными UUID, количество меньше 10 | Значение по умолчанию `null`           |
| `forwardMode`    | `body`       | Обязательный       | `string`       | Тип сообщения: обычное, пересланное, ответ | Должно быть одной из 3 допустимых строк: `none`, `forward`, `reply` | Значение по умолчанию `none` |
| `originalMessageId` | `body`    | Необязательный     | `string`       | Оригинальное сообщение для пересылки или ответа | Должен быть валидным UUID. Если `forwardMode` не `none`, то должно быть значение | Значение по умолчанию `null` |

## 7. Структура ответа  

| **Поле**         | **Передача**   | **Тип данных** | **Обязательность** | **Описание**                                         | **Допустимые значения**             |
|------------------|----------------|----------------|--------------------|------------------------------------------------------|-------------------------------------|
| `Location`       | `header`       | `string`       | Обязательный       | Ссылка на созданное сообщение                        | Валидная относительная ссылка       |

## 8. Алгоритм обработки запроса

- ### 8.1 Валидации
  - Валидация `conversationId` на уровне роутинга на соответствие UUID.
  - Валидация `content`, `attachments` и связки `forwardMode` с `originalMessageId` на уровне эндпоинта.

- ### 8.2 Обработки

  #### Если `forwardMode` не `none`:
    - Получаем `Conversation` по `convesationId` из запроса и получаем нужный обработчик по `conversation_type`.
    - Для **Групповых чатов:**
      - Получаем информацию об участнике из `GroupChatMembers` и проверяем, что пользователь состоит в чате и имеет право писать.
      - Проверяем, чтобы `mutedTill` был `null` или меньше текущего времени.
    - Для **Каналов**:
      - Получаем информацию об участнике из `ChannelMembers` и проверяем, что пользователь состоит в канале и имеет право писать.
    - Получаем `ConversationMessages`, где `id = originalMessageId`.
    - Если `conversation_id` у оригинального сообщения не совпадает с `conversationId` из запроса:
      - Получаем `Conversation` по `conversation_id` из сообщения.
      - Узнаем нужный `conversation_type` из `Conversation`.
      - Проверяем, есть пользователь в `PersonalChatMember`/`GroupChatMembers`/`ChannelMembers` по `conversation_id` и `user_id`.
    - Через `Redis` получаем позицию следующего сообщения.
    - Копируем оригинальное сообщение с новой `metadata`, `position` и `id`.
    - Добавляем сообщение в таблицу `ConversationMessages`.
    - Если у оригинального сообщения есть `attachments`:
      - Добавляем в таблицу `FilesMessages` записи с новым `message_id` и всеми `file_id` из оригинального сообщения.
    - Находим всех участников чата из `PersonalChatMember`/`GroupChatMembers`/`ChannelMembers` по `conversation_id`.
    - Добавляем в таблицу `Outbox` запись для уведомлений.
    
  #### Если `forwardMode` `none`:
    - Получаем `Conversation` по `convesationId` из запроса и получаем нужный обработчик по `conversation_type`.
    - Для **Групповых чатов:**
      - Получаем информацию об участнике из `GroupChatMembers` и проверяем, что пользователь состоит в чате и имеет право писать.
      - Проверяем, чтобы `mutedTill` был `null` или меньше текущего времени.
    - Для **Каналов**:
      - Получаем информацию об участнике из `ChannelMembers` и проверяем, что пользователь состоит в канале и имеет право писать.
    - Через `Redis` получаем позицию следующего сообщения.
    - Создаем запись в `ConversationMessages`.
    - Если у сообщения есть `attachments`:
      - Через таблицу `Files` проверяем, что у всех `attachments` по `id` `sender_id` является текущим пользователем.
      - Добавляем в таблицу `FilesMessages` записи с новым `message_id` и всеми `file_id` из `attachments`.
    - Находим всех участников чата из `PersonalChatMember`/`GroupChatMembers`/`ChannelMembers` по `conversation_id`.
    - Добавляем в таблицу `Outbox` запись для уведомлений.

- ### 8.3 Наполнение из БД
  - `id` из `ConversationMessages`

- ### 8.4 Используемые таблицы
  - `Conversations`
  - `PersonalChatMembers`/`GroupChatMembers`/`ChannelMembers`
  - `Files`
  - `FilesMessages`
  - `ConversationMessages`
  - `Outbox`

- ### 8.5 Вызовы других систем в рамках обработки
  - **Keycloak:**
    - Запрос метаданных авторизации для проверки подлинности токена (если их нет в кэше)  

## 9. Код состояния ответа

- `201 Created`: Успешное выполнение запроса.
- `400 Bad Request`: Введенные данные невалидны.
- `401 Unauthorized`: Отсутствует или неверный токен.
- `403 Forbiddeb`: Пользователь не является участником чата или отсутствуют права на оправку сообщений.
- `500 Internal Server Error`: Внутренняя ошибка сервера.

## 10. Ошибки

- ### 400 Bad Request
  ```json
  {
    "type": "https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.1",
    "title": "VALIDATION_FAILED",
    "status": 400,
    "errors": {
      "content": [
        {
          "message": "LENGTH_MUST_BE_AT_MAX",
          "localizationValues": {
            "maxLength": 3000,
            "totalLength": 3001
          }
        }
      ]
    }
  }
  ```

- ### 401 Unauthorized

  - **Response body:** Отсутствует.

- ### 403 Forbidden

  - **Response Body:**
    ```json 
    {
      "title": "title",
      "status": 403
    }
    ```

  - **Titles:**
    - `NOT_CHAT_MEMBER`: Пользователь не состоит в чате.
    - `WAS_BANNED`: Пользователь был забанен в чате.
    - `WAS_EXCLUDED`: Пользователь был исключен из чата.
    - `WAS_MUTED`: Пользователь не может сейчас отправлять сообщения.
    - `NOT_ENOUGH_PERMISSIONS`: Пользователь не может отправлять сообщения.

- ### 404 Not Found

  - **Response Body:** Отсутствует, если проблема в неверном формате `conversationId`.

  - **Response Body:**
  ```json
    "title": "NOT_FOUND",
    "status": 404,
    "placeholderData": {
      "entityName": "ConversationMessage"
    }
  ```

- ### 500 Internal Server Error

  - **Response body:**
    ```json 
    {
      "title": "INTERNAL_SERVER_ERROR",
      "status": 500
    }
    ```

## 11. Примеры запроса и ответа

### Пример запроса

```http
POST /c/4d0a8fa6-364f-4141-b0d3-b21cacaf300a/send HTTP/1.1  
Host: api.messenger.com  
Content-Type: application/json  
Authorization: Bearer token
```

**Request Body:**
```json
{
  "content": "message",
  "attachments": null,
  "forwardMode": "none",
  "originalMessageId": null
}
```

### Пример ответа

```http
HTTP/1.1 201 Created  
Location: /message/4d0a8fa6-364f-4141-b0d3-b21cacaf300a
Date: Tue, 23 Jan 2025 12:00:00 GMT
```
