// src/api/expenses.js

const API_URL = 'http://localhost:3000/v1/expense';

export const fetchExpenses = async () => {
    const response = await fetch(API_URL);
    if (!response.ok) {
        throw new Error('Failed to fetch expenses');
    }
    return response.json();
};

export const fetchExpenseById = async (id) => {
    const response = await fetch(`${API_URL}/${id}`);
    if (!response.ok) {
        throw new Error('Failed to fetch expense');
    }
    return response.json();
};

export const createExpense = async (expense) => {
    const response = await fetch(API_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(expense),
    });
    if (!response.ok) {
        throw new Error('Failed to create expense');
    }
    return response.json();
};

export const updateExpense = async (id, expense) => {
    const response = await fetch(`${API_URL}/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(expense),
    });
    if (!response.ok) {
        throw new Error('Failed to update expense');
    }
    return response.json();
};

export const deleteExpense = async (id) => {
    const response = await fetch(`${API_URL}/${id}`, {
        method: 'DELETE',
    });
    if (!response.ok) {
        throw new Error('Failed to delete expense');
    }
    return response.json();
};
