import Badge from './Badge';
import Metric from './Metric';
import { BTN, TH, TD, peso, signed } from '../lib/utils';
import { formatName, formatPayrollDateRange, formatPayrollStatus, roundHundredths, summarizeDisbursements } from '../lib/payrollApi';

export default function PayrollDetails({
    payroll,
    disbursements,
    loading,
    deleting,
    actionError,
    onDeleteDraft
}) {
    if (!payroll) return (
        <div className='rounded-xl border border-dashed border-ink/15 bg-white p-8 text-center text-sm text-ink/50'>
            Select a payroll from the table above to see its breakdown and linked disbursements.
        </div>
    );
    const statusBadge = formatPayrollStatus(payroll.payroll_status);
    const isDraft = String(payroll.payroll_status).toLowerCase() == 'draft';
    const canDeleteDraft = isDraft && Number(payroll.aides_paid_count) === 0;
    const totals = summarizeDisbursements(disbursements);
    return (
        <section className='space-y-4 rounded-xl border border-ink/10 bg-white p-5'>
            <div className='flex flex-wrap items-start justify-between gap-3 border-b border-ink/10 pb-4'>
                <div>
                    <div className='flex items-center gap-2.5'>
                        <h2 className='text-lg font-semibold text-ink'>{payroll.payroll_code || 'Payroll'}</h2>
                        <Badge value={statusBadge}/>
                    </div>
                    <p className='mt-0.5 text-sm text-ink/60'>
                        Period: {formatPayrollDateRange(payroll.start_date, payroll.end_date)}
                        {payroll.approver?.employee_name && (
                            <>- Approved by {payroll.approver.employee_name}</>
                        )}
                    </p>
                </div>
                { /* TODO: Other actions unimplemented */ }
                <div className='flex flex-wrap items-center p-3'>
                    { isDraft && (
                        <button
                            type='button'
                            className={BTN.ghost}
                            disabled={!canDeleteDraft || deleting}
                            onClick={() => onDeleteDraft(payroll.payroll_id)}
                            title={
                                canDeleteDraft
                                    ? 'Soft-delete this empty draft'
                                    : 'Detach linked disbursements before deleting'
                            }
                        >{deleting ? 'Deleting...' : 'Delete draft'}</button>
                    )}
                </div>
            </div>
            {actionError && (
                <p className='rounded-lg bg-red-50 px-3 py-2 text-xs font-medium text-red-700'>{actionError}</p>
            )}
            { /* Breakdown */ }
            <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
                <Metric label='Manongs paid' value={payroll.aides_paid_count ?? 0} hint={`${disbursements.length} disbursement${disbursements.length === 1 ? '' : 's'}`} />
                <Metric label='Gross services' value={peso(totals.gross)} />
                <Metric label='Platform commission' value={signed(-totals.commission)} hint='Summed per booking' />
                <Metric label='Net payout' value={peso(roundHundredths(payroll.total_payment))} hint={`Adjustments: ${signed(totals.adjustment)}`} />
            </div>
            { /* Disbursements under this payroll */ }
            <div className='overflow-x-auto rounded-xl border border-ink/10'>
                <table className='w-full text-sm'>
                    <thead className='border-b border-ink/10 bg-ink/[0.02]'>
                        <tr>
                            <th className={TH}>Disbursement</th>
                            <th className={TH}>Booking</th>
                            <th className={TH}>Manong</th>
                            <th className={TH}>Gross</th>
                            <th className={TH}>Commission</th>
                            <th className={TH}>Adjustment</th>
                            <th className={TH}>Final Payout</th>
                            <th className={TH}>Status</th>
                        </tr>
                    </thead>
                    <tbody className='divide-y divide-ink/10'>
                        {loading ? (
                            <tr>
                                <td colspan={7} className='px-4 py-6 text-center text-ink/50'>
                                    Loading disbursements...
                                </td>
                            </tr>
                        ) : disbursements.length === 0 ? (
                            <tr>
                                <td colspan={7} className='px-4 py-6 text-center text-ink/50'>
                                    No disbursements linked to this payroll.
                                </td>
                            </tr>
                        ) : (
                            disbursements.map((d) => {
                                const gross = roundHundredths(d.aide_gross_payment);
                                const commission_rate = roundHundredths(d.commission_rate ?? 0.15);
                                const commission = roundHundredths(gross * commission_rate)
                                const adjustment_fee = roundHundredths(d.adjustment_fee);
                                const payout = roundHundredths(d.grand_total);
                                const payment_tag = d.booking?.payment_method
                                    ? d.booking.payment_method.toUpperCase()
                                    : null;
                                return (
                                    <tr key={d.disbursement_id} className='hover:bg-ink/[0.02]'>
                                        <td className={`${TD} font-mono text-xs font-medium`}>
                                            {d.disbursement_code || d.disbursement.id.slice(0, 8)}
                                        </td>
                                        <td className={TD}>
                                            <div className='font-mono text-xs font-medium text-ink'>
                                                {d.booking?.booking_code || `${d.booking_id.slice(0, 8)}...`}
                                            </div>
                                            {d.booking && (
                                                <div className='mt-0.5 text-xs text-ink/50'>
                                                    {[d.booking.service_type,payment_tag].filter(Boolean).join(' | ')}
                                                </div>
                                            )}
                                        </td>
                                        <td className={TD}>
                                            <div className='font-medium text-ink'>
                                                {formatName(d.aide, d.aide_id)}
                                            </div>
                                            {d.aide?.phone_number && (
                                                <div className='mt-0.5 text-xs text-ink/50'>
                                                    {d.aide.phone_number}
                                                </div>
                                            )}
                                        </td>
                                        <td className={TD}>{peso(gross)}</td>
                                        <td className={`${TD} text-ink/70`}>
                                            {signed(-commission)}
                                            <span>({Math.round(rate * 100)}%)</span>
                                        </td>
                                        <td className={TD}>{signed(adjustment)}</td>
                                        <td className={`${TD} font-semibold`}>{peso(payout)}</td>
                                        <td className={TD}>
                                            <Badge value={d.processed_date ? 'Processed' : 'Pending'} />
                                        </td>
                                    </tr>
                                );
                            })
                        )}
                    </tbody>
                </table>
            </div>
            { /* To be continued */ }
        </section>
    )
}
