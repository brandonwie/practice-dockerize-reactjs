import { useState } from 'react';
import logo from './logo.svg';
import './App.css';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className='App'>
      <header className='App-header'>
        <img src={logo} className='App-logo' alt='logo' />
        <p>
          Edit <code>src/App.tsx</code> and save to reload.
        </p>
        <a
          className='App-link'
          href='https://reactjs.org'
          target='_blank'
          rel='noopener noreferrer'
        >
          Learn React
        </a>
        <p>{`REACT_APP_NAME ${process.env.REACT_APP_NAME}`}</p>
        {/*! to test HMR */}
        <p style={{ color: 'pink' }}>{count}</p>
        <button onClick={() => setCount(count + 1)}>add</button>
      </header>
    </div>
  );
}

export default App;
