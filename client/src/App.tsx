import { useState } from 'react'
import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom';
import ExpensesPage from "./ExpensesPage.tsx";


function App() {
    return (
        <Router>
            <Routes>
                {/*<Route path="/login" element={<LoginPage onLogin={handleLogin} />} />*/}
                {/*<Route path="/signup" element={<SignUpPage />} />*/}
                <Route
                    path="/"
                    element=<ExpensesPage />
                />
            </Routes>
        </Router>
    );

}

export default App
