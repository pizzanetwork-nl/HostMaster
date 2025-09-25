import React, { useState, useEffect } from "react";
import axios from "axios";

function App() {
  const [gameservers, setGameservers] = useState([]);

  useEffect(() => {
    axios.get(`${import.meta.env.VITE_PUBLIC_URL}/api/pterolite/list`)
      .then(res => setGameservers(res.data))
      .catch(console.error);
  }, []);

  return (
    <div style={{padding:"2rem"}}>
      <h1>PteroLite Demo</h1>
      <ul>
        {gameservers.map(g => <li key={g.id}>{g.name} - {g.status}</li>)}
      </ul>
    </div>
  );
}

export default App;
