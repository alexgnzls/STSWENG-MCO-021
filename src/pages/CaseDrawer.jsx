import { useState } from 'react'
import { supabase } from "../lib/supabase.js";
import { addTicketNote } from "../lib/supportApi.js";
import {cx, BTN, INPUT} from '../lib/utils'
import Badge from "../components/Badge.jsx";

/**
 * Case drawer. One scroll: linked records (D04) > complaint > notes (D05) > resolution (D07).
 * The footer action follows the state machine Open > In Review > Resolved > Closed.
 */

export default function CaseDrawer({ caseSelected, onPatch, onClose }) {
    const [note, setNote] = useState('')
    const [resolution, setResolution] = useState(caseSelected.resolution)
    const [saving, setSaving] = useState(false);

    const handleAddNote = async () => {
        if (!note.trim() || saving) return; // prevent adding empty notes or adding multiple notes while saving
        setSaving(true);
        try {
            const { data: { user } } = await supabase.auth.getUser();
            const savedNote = await addTicketNote(caseSelected.id, note.trim(), user.id);

            onPatch(caseSelected.id, { notes: [...caseSelected.notes, savedNote] });
            setNote('');
        } catch (error) {
            console.error('Failed to add note:', error.message);
        } finally {
            setSaving(false);
        }
    };

    /*
        Start review: Open -> In Review, assign to self if unassigned
        - PATCH /support-cases/:id { status: 'In Review', assignee: 'You' }
     */
    const startReview = () => onPatch(caseSelected.id, { status: 'In Review', assignee: caseSelected.assignee === 'Unassigned' ? 'You' : caseSelected.assignee })

    /*
        Resolve ticket: In Review -> Resolved, requires resolution text
        - PATCH /support-cases/:id { status: 'Resolved', resolution: '...' }
     */
    const resolveTicket = () => resolution.trim() && onPatch(caseSelected.id, { status: 'Resolved', resolution: resolution.trim() })

    /*
        Close ticket: Resolved -> Closed
        - PATCH /support-cases/:id { status: 'Closed' }
     */
    const closeTicket = () => onPatch(caseSelected.id, { status: 'Closed' })

    const links = [['Resident', caseSelected.resident], ['Aide', caseSelected.aide], ['Booking', caseSelected.booking], ['Property', caseSelected.property], ['Transaction', caseSelected.txn]]

    return (
        <div className="fixed inset-0 z-40 flex justify-end bg-ink/40" onClick={onClose}>
            <aside className="flex h-full w-full max-w-lg flex-col bg-white shadow-2xl" onClick={(e) => e.stopPropagation()}>
                <header className="flex items-start justify-between border-b border-ink/10 p-5">
                    <div>
                        <div className="flex items-center gap-2"><h2 className="text-lg font-semibold">{caseSelected.id}</h2><Badge value={caseSelected.status} /></div>
                        <p className="mt-0.5 text-sm text-ink/60">{caseSelected.category}, assigned to {caseSelected.assignee}</p>
                    </div>
                    <button onClick={onClose} aria-label="Close case panel" className={BTN.ghost}>Close</button>
                </header>

                <div className="flex-1 space-y-6 overflow-y-auto p-5">
                    <section>
                        <h3 className="mb-2 text-sm font-semibold">Linked records</h3>
                        <dl className="divide-y divide-ink/5 rounded-lg border border-ink/10 text-sm">
                            {links.map(([k, v]) => (
                                <div key={k} className="flex justify-between gap-4 px-3 py-2"><dt className="text-ink/50">{k}</dt><dd className="text-right font-medium">{v}</dd></div>
                            ))}
                        </dl>
                    </section>

                    <section>
                        <h3 className="mb-2 text-sm font-semibold">Complaint</h3>
                        <p className="rounded-lg bg-cream p-3 text-sm leading-relaxed">{caseSelected.description}</p>
                    </section>

                    <section>
                        <h3 className="mb-2 text-sm font-semibold">Notes and responses</h3>
                        <ul className="space-y-2">
                            {caseSelected.notes.map((n, i) => (
                                <li key={i} className="rounded-lg border border-ink/10 p-3 text-sm">
                                    <p>{n.text}</p><p className="mt-1 text-xs text-ink/50">{n.by}, {n.at}</p>
                                </li>
                            ))}
                            {!caseSelected.notes.length && <li className="text-sm text-ink/50">No notes yet. Record every call or message so the history is complete.</li>}
                        </ul>
                        {caseSelected.status !== 'Closed' && (
                            <div className="mt-3 flex gap-2">
                                <input className={INPUT} value={note} placeholder="Add a note or response" onChange={(e) => setNote(e.target.value)} />
                                <button className={BTN.dark} onClick={handleAddNote} disabled={!note.trim()}>Add note</button>
                            </div>
                        )}
                    </section>

                    {caseSelected.status !== 'Open' && (
                        <section>
                            <h3 className="mb-2 text-sm font-semibold">Resolution</h3>
                            <textarea rows={3} className={INPUT} value={resolution} disabled={caseSelected.status !== 'In Review'}
                                      placeholder="Describe how the issue was resolved" onChange={(e) => setResolution(e.target.value)} />
                        </section>
                    )}
                </div>

                <footer className="border-t border-ink/10 p-4">
                    {caseSelected.status === 'Open' && <button className={cx(BTN.primary, 'w-full')} onClick={startReview}>Start review</button>}
                    {caseSelected.status === 'In Review' && <button className={cx(BTN.primary, 'w-full')} onClick={resolveTicket} disabled={!resolution.trim()}>Resolve case</button>}
                    {caseSelected.status === 'Resolved' && <button className={cx(BTN.dark, 'w-full')} onClick={closeTicket}>Close case</button>}
                    {caseSelected.status === 'Closed' && <p className="text-center text-sm text-ink/50">This case is closed and kept in the support history.</p>}
                </footer>
            </aside>
        </div>
    )
}