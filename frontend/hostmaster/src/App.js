import React, { useState, useEffect } from "react";
import axios from "axios";

function App() {
  const [vpsList, setVpsList] = useState([]);

  useEffect(() => {
    axios.get(`${import.meta.env.VITE_PUBLIC_URL}/api/vps/list`)
      .then(res => setVpsList(res.data))
      .catch(console.error);
  }, []);

  return (
    <div style={{padding:"2rem"}}>
      <h1>HostMaster Demo</h1>
      <ul>
        {vpsList.map(v => <li key={v.id}>{v.name} - {v.status}</li>)}
      </ul>
    </div>
  );
}

export default App;
