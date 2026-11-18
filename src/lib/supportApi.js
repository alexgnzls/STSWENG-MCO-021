import { supabase } from "./supabase.js";

const convertUI2DB = {
    "Open": "open",
    "In Review": "review",
    "Resolved": "resolved",
    "Closed": "closed"
}

const convertDB2UI = {
    "open": "Open",
    "review": "In Review",
    "resolved": "Resolved",
    "closed": "Closed"
}

/*
 * Format a date string from the database.
 * The format includes the month (short), day, year, and time (hour and minute).
 *
 * @param {string} date - A date string from the database.
 * @returns {string} - A formatted date string for display in the UI.
 */
const formatDate = (date) => {
    if (!date) return 'N/A';
    new Date(date).toLocaleString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        minute: '2-digit',
    });
};

/*
 * Format a row from the database into the format expected by the UI.
 * This includes converting status values, formatting dates, and handling missing data.
 *
 * @param {Object} row - A single row from the database representing a support case.
 */
function formatRow (row) {
    return {
        id: row.ticket_id,
        category: row.ticket_category,
        status: convertDB2UI[row.ticket_status] || 'Open',
        created: formatDate(row.receive_date),
        resident: row.resident?.full_name || row.resident_id || 'N/A',
        aide: row.aide?.full_name || row.aide_id || 'N/A',
        property: row.booking?.property_name || 'N/A',
        booking: row.booking_id || 'N/A',
        txn: row.booking?.transaction_id || 'N/A',
        assignee: row.assigned_employee?.employee_name || 'Unassigned',
        description: row.ticket_description || '',
        notes: (row.notes || []).map((n) => ({
            id: n.note_id,
            by: n.author?.employee_name || 'Admin',
            at: formatDate(n.creation_date),
            text: n.note || '',
        })),
        resolution: row.ticket_remarks || '',
    }
}

/*
 * Fetch all support cases from the database, including related data from employees, residents, aides, and bookings.
 *
 * @returns {Promise<Array>} - A promise that resolves to an array of formatted support cases.
 */
export async function fetchCases() {
    const { data, error } = await supabase
        .from('adm_tickets')
        .select(`
            *,
            assigned_employee:adm_employees(employee_id, employee_name),
            resident:usr_residents(*),
            aide:aides(*),
            booking:usr_bookings(*),
            notes:adm_ticket_notes(
                note_id,
                note,
                creation_date,
                author:adm_employees(employee_name)
            )
        `)
        .order('receive_date', { ascending: false })
        .order('creation_date', { referencedTable: 'notes', ascending: true });
    if (error) {
        console.error('Error fetching cases:', error);
    }
    return data.map(formatRow);
}

/*
 * This functions adds a note to the specified ticket in the database.
 *
 * @param {string} ticketId - The ID of the ticket to which the note will be added.
 * @param {string} noteText - The text of the note to be added.
 * @param {string} currentAdminId - The ID of the currently logged-in admin adding the note.
 *
 * @returns {Promise<Object>} - A promise that resolves to an object containing the added note's details
 */
export async function addTicketNote(ticketId, noteText, currentAdminId) {
    const { data, error } = await supabase
        .from('adm_ticket_notes')
        .insert({
            ticket_id: ticketId,
            note: noteText,
            employee_id: currentAdminId
        })
        .select(`
            note_id, 
            note,
            creation_date,
            author:adm_employees(employee_name)
        `)
        .single();

    if (error) {
        console.error('Error adding note:', error);
    }

    return {
        id: data.note_id,
        by: data.author?.employee_name || 'Admin',
        at: formatDate(data.creation_date),
        text: data.note,
    }
}