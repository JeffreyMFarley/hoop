import './base.css';
import App from './App';
import React from 'react';
import ReactDOM from 'react-dom';

// ----------------------------------------------------------------------------
// Initial Render

ReactDOM.render(
  <React.StrictMode>
      <App />
  </React.StrictMode>,
  document.getElementById( 'app' )
);
