import { useState } from 'react';
import Modal from './Modal';
import { BTN, INPUT } from '../lib/utils';
import { createPayroll } from '../lib/payrollApi';

export default function PayrollModal({ onClose, onCreated }) {
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [autoAssign, setAutoAssign] = useState(true);
    const [onSubmit, setOnSubmit] = useState(false);
    const [error, setError] = useState('');

    const HandleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        if (!startDate || !endDate) {
            setError('Start and end dates are required.');
            return;
        }
        if (startDate > endDate) {
            setError('Start date cannot be later than or the same as end date.');
            return;
        }
        setOnSubmit(true);
        try {
            const created = await createPayroll({
                start_date: startDate,
                end_date: endDate,
                autoAssign
            });
            onCreated(created);
        } catch (ex) {
            setError(ex.message);
        } finally {
            setOnSubmit(false);
        }
    };

    return (
        <Modal title='Create payroll run...' onClose={ onSubmit ? undefined : onClose }>
            <form onSubmit={HandleSubmit} className='space-y-4'>
                <div className='grid grid-cols-2 gap-3'>
                    <div>
                        <label className='mb-1 block text-xs font-medium text-ink/70'>Start Date</label>
                        <input
                            type='date'
                            className={INPUT}
                            value={startDate}
                            onChange={(e) => setStartDate(e.target.value)}
                            required
                        />
                    </div>
                    <div>
                        <label className='mb-1 block text-xs font-medium text-ink/70'>End Date</label>
                        <input
                            type='date'
                            className={INPUT}
                            value={endDate}
                            min={startDate || undefined}
                            onChange={(e) => setEndDate(e.target.value)}
                            required
                        />
                    </div>
                </div>
                <label className='flex items-start gap-2.5 rounded-lg border border-ink/10 bg-ink/[0.02] p-3 text-sm'>
                    <input
                        type='checkbox'
                        checked={autoAssign}
                        onChange={(e) => setAutoAssign(e.target.checked)}
                        className='mt-0.5 h-4 w-4 accent-ink'
                    />
                    <span>
                        <span className='font-medium text-ink'>Auto-assign eligible disbursements</span>
                        <span className='mt-0.5 block text-xs text-ink/60'>
                            Includes unassigned disbursements created within this period that have no open or under-review tickets.
                        </span>
                    </span>
                </label>
                {error && (
                    <p className='rounded-lg bg-red-50 px-3 py-2 text-xs font-medium text-red-700'>{error}</p>
                )}
                <div className='flex justify-end gap-2 pt-2'>
                    <button type='button' className={BTN.ghost} onClick={onClose} disabled={onSubmit}>Cancel</button>
                    <button type='submit' className={BTN.primary} disabled={onSubmit}>{onSubmit ? 'Creating...' : 'Create draft'}</button>
                </div>
            </form>
        </Modal>
    );
}
