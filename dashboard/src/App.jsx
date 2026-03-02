import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import AlertQueue from './pages/AlertQueue';
import AlertDetail from './pages/AlertDetail';
import DashboardStats from './pages/DashboardStats';

export default function App() {
  return (
    <BrowserRouter>
      <div className="flex min-h-screen bg-slate-950">
        <Sidebar />
        <main className="flex-1 p-8 overflow-auto">
          <Routes>
            <Route path="/" element={<AlertQueue />} />
            <Route path="/alert/:id" element={<AlertDetail />} />
            <Route path="/dashboard" element={<DashboardStats />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}
