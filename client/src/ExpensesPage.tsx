import useExpenseStore from "./hooks/useExpenseStore.ts";
import {useEffect} from "react";

const ExpensesPage = () => {
    const { loadExpenses, expenses } = useExpenseStore();

    useEffect(() => {
        loadExpenses();
    }, []);

    return (
        <ul>
            {
                expenses.map((expense) => (
                    <div key={expense.time} className='my-5 border-amber-200 border-2 border-solid '>
                        <div>
                            amount: {expense.amount}
                        </div>
                        <div>
                            time: {expense.time}
                        </div>
                        <div>
                            user: {expense.user_id}
                        </div>

                    </div>
                ))
            }
        </ul>
    )
}

export default ExpensesPage;