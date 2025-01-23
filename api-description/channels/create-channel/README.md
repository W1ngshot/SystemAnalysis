# Описание эндпоинта `Создание канала`

## 1. Протокол взаимодействия  

**HTTP/1.1 & REST**  

## 2. Метод запроса  

**POST**  

## 3. URL  

`/channel/create`  

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

| **Параметр**     | **Передача** | **Обязательность** | **Тип данных** | **Описание**    | **Условия валидации**                  | **Значения по умолчанию / Допустимые значения** |
|----------------- |--------------|--------------------|----------------|-----------------|----------------------------------------|-------------------------------------------------|
| `title`          | `body`       | Обязательный       | `string`       | Название канала | Длина должна быть от 1 до 100 символов | Нет значения по умолчанию                       |

## 7. Структура ответа  

| **Поле**         | **Передача**   | **Тип данных** | **Обязательность** | **Описание**                                         | **Допустимые значения**             |
|------------------|----------------|----------------|--------------------|------------------------------------------------------|-------------------------------------|
| `Location`       | `header`       | `string`       | Обязательный       | Ссылка на созданный чат                              | Валидная ссылка                     |

## 8. Алгоритм обработки запроса

- ### 8.1 Валидации
  - Валидация `title` на уровне эндпоинта.

- ### 8.2 Обработки
  - Создание сущности `Conversations` с `conversation_type = "channel"`.
  - Создание сущности `ChannelInfos` с нужным `conversation_id` из предыдущей сущности.
  - Создание сущности `ChannelMembers` с `is_admin = true` и `is_owner = true`.
  - Создание сущности `ConversationUserStatutes`.
  - Создание сущности `ConversationMessages` с `sender_id = Guid.Empty` (Системное сообщение о создании канала).
  - Создание сущности `Outbox` с информации о создании канала.

- ### 8.3 Наполнение из БД
  - `conversation_id` из `Conversations

- ### 8.4 Используемые таблицы
  - `Conversations`
  - `ChannelInfos`
  - `ChannelMembers`
  - `ConversationUserStatutes`
  - `ConversationMessages`
  - `Outbox`

- ### 8.5 Вызовы других систем в рамках обработки
  - **Keycloak:**
    - Запрос метаданных авторизации для проверки подлинности токена (если их нет в кэше)  

## 9. Код состояния ответа

- `201 Created`: Успешное выполнение запроса.
- `400 Bad Request`: Введенные данные невалидны.
- `401 Unauthorized`: Отсутствует или неверный токен.
- `500 Internal Server Error`: Внутренняя ошибка сервера.

## 10. Ошибки

- ### 400 Bad Request
  ```json
  {
    "type": "https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.1",
    "title": "VALIDATION_FAILED",
    "status": 400,
    "errors": {
      "title": [
        {
          "message": "LENGTH_MUST_BE_AT_LEAST",
          "localizationValues": {
            "minLength": 1,
            "totalLength": 0
          }
        }
      ]
    }
  }
  ```

  ```json
  {
    "type": "https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.1",
    "title": "VALIDATION_FAILED",
    "status": 400,
    "errors": {
      "name": [
        {
          "message": "LENGTH_MUST_BE_AT_MAX",
          "localizationValues": {
            "maxLength": 100,
            "totalLength": 101
          }
        }
      ]
    }
  }
  ```

- ### 401 Unauthorized

  - **Response body:** Отсутствует.

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
POST /channel/create HTTP/1.1  
Host: api.messenger.com  
Content-Type: application/json  
Authorization: Bearer token
```

**Request Body:**
```json
{
  "title": "Title"
}
```

### Пример ответа

```http
HTTP/1.1 201 Created  
Location /channel/4d0a8fa6-364f-4141-b0d3-b21cacaf300a/info
Date: Tue, 23 Jan 2025 12:00:00 GMT
```
