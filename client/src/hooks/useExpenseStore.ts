// src/hooks/useExpenseStore.js

import { useState, useEffect } from 'react';
import { fetchExpenses, fetchExpenseById, createExpense, updateExpense, deleteExpense } from '../api/expense';

const useExpenseStore = () => {
    const [expenses, setExpenses] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const loadExpenses = async () => {
        setLoading(true);
        try {
            const data = await fetchExpenses();
            setExpenses(data);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const loadExpenseById = async (id) => {
        setLoading(true);
        try {
            const data = await fetchExpenseById(id);
            return data;
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const addExpense = async (expense) => {
        setLoading(true);
        try {
            const newExpense = await createExpense(expense);
            setExpenses((prevExpenses) => [...prevExpenses, newExpense]);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const editExpense = async (id, expense) => {
        setLoading(true);
        try {
            const updatedExpense = await updateExpense(id, expense);
            setExpenses((prevExpenses) => prevExpenses.map((e) => (e.id === id ? updatedExpense : e)));
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const removeExpense = async (id) => {
        setLoading(true);
        try {
            await deleteExpense(id);
            setExpenses((prevExpenses) => prevExpenses.filter((e) => e.id !== id));
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadExpenses();
    }, []);

    return {
        expenses,
        loading,
        error,
        loadExpenses,
        loadExpenseById,
        addExpense,
        editExpense,
        removeExpense,
    };
};

export default useExpenseStore;
