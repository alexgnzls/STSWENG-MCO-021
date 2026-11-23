import { useCallback, useEffect, useMemo, useState } from 'react';
import Badge from '../components/Badge';
import Metric from '../components/Metric';
import PayrollModal from '../components/PayrollModal';
import PayrollDetails from '../components/PayrollDetails';
import { BTN, TH, TD, cx, peso } from '../lib/utils';
import {
  fetchPayrolls,
  fetchPayrollDisbursements,
  formatPayrollDateRange,
  formatPayrollStatus,
  roundHundredths,
  deletePayroll,
} from '../lib/payrollApi';

const STATUS_FILTERS = ['all', 'draft', 'pending', 'processed'];

export default function PayrollPage() {
  const [payrolls, setPayrolls] = useState([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedId, setSelectedId] = useState(null);
  const [disbursements, setDisbursements] = useState([]);

  const [loadingList, setLoadingList] = useState(true);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [pageError, setPageError] = useState('');
  const [actionError, setActionError] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);

  const loadPayrolls = useCallback(async (preferredId = null) => {
    setLoadingList(true);
    setPageError('');
    try {
      const rows = await fetchPayrolls();
      setPayrolls(rows);
      setSelectedId((prev) => {
        if (preferredId && rows.some((r) => r.payroll_id === preferredId)) {
          return preferredId;
        }
        if (prev && rows.some((r) => r.payroll_id === prev)) {
          return prev;
        }
        return rows[0]?.payroll_id ?? null;
      });
    } catch (err) {
      setPageError(err.message || 'Failed to load payroll runs.');
    } finally {
      setLoadingList(false);
    }
  }, []);

  useEffect(() => {
    loadPayrolls();
  }, [loadPayrolls]);

  useEffect(() => {
    if (!selectedId) {
      setDisbursements([]);
      return;
    }

    let cancelled = false;
    setLoadingDetail(true);
    setActionError('');

    fetchPayrollDisbursements(selectedId)
      .then((rows) => {
        if (!cancelled) setDisbursements(rows);
      })
      .catch((err) => {
        if (!cancelled) setActionError(err.message || 'Failed to load disbursements.');
      })
      .finally(() => {
        if (!cancelled) setLoadingDetail(false);
      });

    return () => {
      cancelled = true;
    };
  }, [selectedId]);

  const filteredPayrolls = useMemo(() => {
    if (statusFilter === 'all') return payrolls;
    return payrolls.filter(
      (p) => String(p.payroll_status).toLowerCase() === statusFilter
    );
  }, [payrolls, statusFilter]);

  const selectedPayroll = useMemo(
    () => payrolls.find((p) => p.payroll_id === selectedId) ?? null,
    [payrolls, selectedId]
  );

  const kpis = useMemo(() => {
    const activeRuns = payrolls.filter(
      (p) => String(p.payroll_status).toLowerCase() !== 'processed'
    ).length;
    const processedTotal = payrolls
      .filter((p) => String(p.payroll_status).toLowerCase() === 'processed')
      .reduce((sum, p) => roundHundredths(sum + Number(p.total_payment || 0)), 0);

    return {
      totalRuns: payrolls.length,
      activeRuns,
      processedTotal,
    };
  }, [payrolls]);

  const handleCreated = async (newPayroll) => {
    setShowCreateModal(false);
    setStatusFilter('all');
    await loadPayrolls(newPayroll?.payroll_id ?? null);
  };

  const handleDeleteDraft = async (payrollId) => {
    setDeleting(true);
    setActionError('');
    try {
      await deletePayroll(payrollId);
      await loadPayrolls();
    } catch (err) {
      setActionError(err.message);
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Bar */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-ink">Payroll</h1>
          <p className="text-sm text-ink/60">
            Create payroll runs and review linked aide disbursements.
          </p>
        </div>

        <button
          type="button"
          className={BTN.primary}
          onClick={() => setShowCreateModal(true)}
        >
          + New Payroll
        </button>
      </div>

      {/* Overview Metrics */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <Metric label="Total Payroll Runs" value={kpis.totalRuns} />
        <Metric
          label="Draft & Pending"
          value={kpis.activeRuns}
          hint="Not yet finalized"
        />
        <Metric
          label="Total Disbursed"
          value={peso(kpis.processedTotal)}
          hint="Processed payrolls"
        />
      </div>

      {pageError && (
        <p className="rounded-lg bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
          {pageError}
        </p>
      )}

      {/* Payroll Runs Table */}
      <section className="rounded-xl border border-ink/10 bg-white">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-ink/10 px-4 py-3">
          <h2 className="text-sm font-semibold text-ink">Payroll Runs</h2>

          <div className="flex gap-1.5">
            {STATUS_FILTERS.map((status) => (
              <button
                key={status}
                type="button"
                onClick={() => setStatusFilter(status)}
                className={cx(
                  'rounded-lg px-3 py-1 text-xs font-medium capitalize transition',
                  statusFilter === status
                    ? 'bg-ink text-cream'
                    : 'bg-ink/5 text-ink/70 hover:bg-ink/10'
                )}
              >
                {status}
              </button>
            ))}
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="border-b border-ink/10 bg-ink/[0.02]">
              <tr>
                <th className={TH}>Payroll Code</th>
                <th className={TH}>Pay Period</th>
                <th className={TH}>Status</th>
                <th className={TH}>Aides</th>
                <th className={TH}>Total Payment</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ink/10">
              {loadingList ? (
                <tr>
                  <td colSpan={5} className="px-4 py-6 text-center text-ink/50">
                    Loading payrolls...
                  </td>
                </tr>
              ) : filteredPayrolls.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-6 text-center text-ink/50">
                    No payroll runs found. Click &ldquo;+ New Payroll&rdquo; to create one.
                  </td>
                </tr>
              ) : (
                filteredPayrolls.map((p) => {
                  const isSelected = p.payroll_id === selectedId;
                  return (
                    <tr
                      key={p.payroll_id}
                      onClick={() => setSelectedId(p.payroll_id)}
                      className={cx(
                        'cursor-pointer transition',
                        isSelected ? 'bg-brand/15' : 'hover:bg-ink/[0.03]'
                      )}
                    >
                      <td className={`${TD} font-mono text-xs font-semibold`}>
                        {p.payroll_code || p.payroll_id.slice(0, 8)}
                      </td>
                      <td className={TD}>
                        {formatPayrollDateRange(p.start_date, p.end_date)}
                      </td>
                      <td className={TD}>
                        <Badge value={formatPayrollStatus(p.payroll_status)} />
                      </td>
                      <td className={TD}>{p.aides_paid_count ?? 0}</td>
                      <td className={`${TD} font-semibold`}>
                        {peso(roundHundredths(p.total_payment))}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* Selected Payroll Detail */}
      <PayrollDetails
        payroll={selectedPayroll}
        disbursements={disbursements}
        loading={loadingDetail}
        deleting={deleting}
        actionError={actionError}
        onDeleteDraft={handleDeleteDraft}
      />

      {/* Create Modal */}
      {showCreateModal && (
        <PayrollModal
          onClose={() => setShowCreateModal(false)}
          onCreated={handleCreated}
        />
      )}
    </div>
  );
}