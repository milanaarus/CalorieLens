// frontend/src/App.jsx
import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [message, setMessage] = useState('Загрузка...');

  // Отправляем запрос на бэкенд при загрузке страницы
  useEffect(() => {
    fetch('/api/health')
      .then(response => response.json())
      .then(data => setMessage(data.status))
      .catch(error => {
        console.error('Ошибка:', error);
        setMessage('Не удалось подключиться к серверу');
      });
  }, []);

  return (
    <div className="App">
      <h1>Calorie AI</h1>
      <p>Статус сервера: <strong>{message}</strong></p>
    </div>
  );
}

export default App;