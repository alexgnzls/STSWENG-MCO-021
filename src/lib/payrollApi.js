import { supabase } from '../lib/supabase';

const STATUS_LABELS = {
    draft: 'Draft',
    pending: 'Pending',
    processed: 'Processed'
};
export const formatName = (aide, fallback = '') => {
    if (!aide) return fallback ? `${fallback.slice(0, 8)}...` : `Manong`;
    const parts = [ aide.first_name, aide.middle_name, aide.last_name, aide.suffix, ]
        .map((p) => (p || '').trim()).filter(Boolean);
    return parts.length > 0
        ? parts.join(' ')
        : fallback ? `${fallback.slice(0, 8)}...` : `Manong`;
};
export const formatPayrollStatus = (s) =>
    STATUS_LABELS[String(s || '').toLowerCase()] || s || 'Draft';
export const formatPayrollDateRange = (start, end) => {
    if (!start || !end) return '-';
    const formatter = (dt) => new Date(`${dt}T00:00:00`)
        .toLocaleDateString('en-PH', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
        }
    );
    return `${formatter(start)} - ${formatter(end)}`;
};
export const roundHundredths = (n) =>
    Math.round((Number(n || 0) + Number.EPSILON) * 100) / 100;
export const summarizeDisbursements = (rows = []) => rows.reduce(
    (acc, row) => {
        const gross = roundHundredths(row.aide_gross_payment);
        const commission = roundHundredths(gross * Number(row.commission_rate ?? 0.15));
        const adjustment = roundHundredths(row.adjustment_fee);
        const total = roundHundredths(row.grand_total);
        return {
            gross: roundHundredths(acc.gross + gross),
            commission: roundHundredths(acc.commission + commission),
            adjustment: roundHundredths(acc.adjustment + adjustment),
            netPayout: roundHundredths(acc.netPayout + total),
        };
    }, { gross: 0, commission: 0, adjustment: 0, netPayout: 0 }
);
export async function fetchPayrolls() {
    const { data, error } = await supabase.from('adm_payrolls')
        .select(`
            payroll_id,
            payroll_code,
            payroll_status,
            start_date,
            end_date,
            aides_paid_count,
            total_payment,
            approval_date,
            approved_by,
            creation_date,
            approver:adm_employees!adm_payrolls_approved_by_fkey(employee_name)
        `)
        .order('start_date', { ascending: false });
    if (error) throw error;
    return data ?? [];
}
export async function fetchPayrollDisbursements(payrollId) {
    const { data, error } = await supabase.from('adm_disbursements')
        .select(`
            disbursement_id,
            disbursement_code,
            payroll_id,
            aide_id,
            booking_id,
            aide_gross_payment,
            commission_rate,
            adjustment_fee,
            grand_total,
            payment_reference_number,
            processed_date,
            creation_date,
            aide:aide_aides(
              id,
              first_name,
              middle_name,
              last_name,
              suffix,
              phone_number
            ),
            booking:usr_bookings (
              booking_id,
              booking_code,
              service_type,
              booking_type,
              payment_method,
              status,
              agreed_price
            )
        `).eq('payroll_id', payrollId)
        .order('creation_date', { ascending: false });
    if (error) throw error;
    return data ?? [];
}
export async function createPayroll({ start_date, end_date, autoAssign = true }) {
    const { data, error } = await supabase.rpc('adm_create_payroll', {
        param_start_date: start_date,
        param_end_date: end_date,
        param_auto_assign: autoAssign,
        param_tz: 'Asia/Manila',
    });
    if (error) {
        if (error.code == '23P01')
            throw new Error('Bound on date range overlaps with an existing active payroll.');
        if (error.code == '23514')
            throw new Error('start_date cannot be later than end_date.');
        if (error.code == '42501')
            throw new Error('Insufficient permission to create payrolls.');
        throw new Error(error.message || 'Unexpected error while creating payroll.');
    }
    return data;
}
export async function deletePayroll(payrollId) {
    const { error } = await supabase.rpc('adm_soft_delete', {
        param_table_name: 'adm_payrolls',
        param_entry_id: payrollId,
    });
    if (error) {
        if (error.code == '23503')
            throw new Error('A disbursement is linked to this draft.');
        throw new Error(error.message || 'Unexpected error while deleting payroll.');
    }
}
