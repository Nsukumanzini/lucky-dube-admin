import 'admin_repository.dart';

class FieldSpec {
  final String key, label;
  final bool required;
  final List<String>? options;
  final EntityKind? reference;
  final bool multiline;
  final String initial;
  const FieldSpec(this.key, this.label,
      {this.required = true,
      this.options,
      this.reference,
      this.multiline = false,
      this.initial = ''});
}

const labels = {
  EntityKind.learner: 'Learners',
  EntityKind.staff: 'Staff',
  EntityKind.schoolClass: 'Classes',
  EntityKind.subject: 'Subjects',
  EntityKind.allocation: 'Teaching allocations',
  EntityKind.timetable: 'Timetable',
  EntityKind.announcement: 'Announcements',
  EntityKind.event: 'School calendar',
  EntityKind.concern: 'Support cases',
  EntityKind.result: 'Results review',
  EntityKind.resource: 'Resources review',
  EntityKind.term: 'Academic terms'
};
List<FieldSpec> schema(EntityKind kind) => [
      const FieldSpec('name', 'Name / title'),
      ...switch (kind) {
        EntityKind.learner => [
            const FieldSpec('classId', 'Class',
                reference: EntityKind.schoolClass),
            const FieldSpec('grade', 'Grade', options: ['8', '9', '10']),
            const FieldSpec('guardian', 'Guardian reference', required: false),
            const FieldSpec('status', 'Status',
                options: ['Active', 'Inactive'], initial: 'Active')
          ],
        EntityKind.staff => [
            const FieldSpec('email', 'Email address'),
            const FieldSpec('speciality', 'Teaching speciality'),
            const FieldSpec('status', 'Status',
                options: ['Active', 'Inactive'], initial: 'Active')
          ],
        EntityKind.schoolClass => [
            const FieldSpec('grade', 'Grade', options: ['8', '9', '10']),
            const FieldSpec('room', 'Classroom'),
            const FieldSpec('capacity', 'Capacity', initial: '35'),
            const FieldSpec('status', 'Status',
                options: ['Active'], initial: 'Active')
          ],
        EntityKind.subject => [
            const FieldSpec('grades', 'Enabled grades', initial: '8,9,10'),
            const FieldSpec('status', 'Status',
                options: ['Active'], initial: 'Active')
          ],
        EntityKind.allocation => [
            const FieldSpec('classId', 'Class',
                reference: EntityKind.schoolClass),
            const FieldSpec('subjectId', 'Subject',
                reference: EntityKind.subject),
            const FieldSpec('teacherId', 'Teacher',
                reference: EntityKind.staff),
            const FieldSpec('status', 'Status',
                options: ['Active'], initial: 'Active')
          ],
        EntityKind.timetable => [
            const FieldSpec('allocationId', 'Teaching allocation',
                reference: EntityKind.allocation),
            const FieldSpec('day', 'Day',
                options: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday'
                ],
                initial: 'Thursday'),
            const FieldSpec('start', 'Start time (HH:mm)', initial: '11:15'),
            const FieldSpec('end', 'End time (HH:mm)', initial: '12:00'),
            const FieldSpec('room', 'Classroom'),
            const FieldSpec('status', 'Status',
                options: ['Active'], initial: 'Active')
          ],
        EntityKind.announcement => [
            const FieldSpec('body', 'Notice content', multiline: true),
            const FieldSpec('audience', 'Audience',
                options: [
                  'All',
                  'Grade 8',
                  'Grade 9',
                  'Grade 10',
                  '8A',
                  '9A',
                  '10A'
                ],
                initial: 'All'),
            const FieldSpec('priority', 'Priority',
                options: ['Normal', 'Important'], initial: 'Normal'),
            const FieldSpec('date', 'Date (YYYY-MM-DD)', initial: '2026-11-26'),
            const FieldSpec('status', 'Status',
                options: ['Draft', 'Published'], initial: 'Draft')
          ],
        EntityKind.event => [
            const FieldSpec('body', 'Event details', multiline: true),
            const FieldSpec('category', 'Category',
                options: [
                  'Academic',
                  'Examinations',
                  'Rehearsal',
                  'Performance',
                  'School event'
                ],
                initial: 'School event'),
            const FieldSpec('date', 'Date (YYYY-MM-DD)', initial: '2026-11-26'),
            const FieldSpec('time', 'Time (HH:mm)', initial: '14:30'),
            const FieldSpec('venue', 'Venue'),
            const FieldSpec('audience', 'Audience',
                options: [
                  'All',
                  'Grade 8',
                  'Grade 9',
                  'Grade 10',
                  '8A',
                  '9A',
                  '10A'
                ],
                initial: 'All'),
            const FieldSpec('status', 'Status',
                options: ['Draft', 'Published'], initial: 'Draft')
          ],
        EntityKind.concern => [
            const FieldSpec('category', 'Concern category',
                options: [
                  'Academic concerns',
                  'Safety concerns',
                  'Bullying',
                  'Harassment',
                  'Technical issues'
                ],
                initial: 'Academic concerns'),
            const FieldSpec('body', 'Case details', multiline: true),
            const FieldSpec('assignedTo', 'Assigned staff member',
                reference: EntityKind.staff),
            const FieldSpec('date', 'Date (YYYY-MM-DD)', initial: '2026-11-26'),
            const FieldSpec('status', 'Status',
                options: ['Open', 'In review', 'Resolved'], initial: 'Open'),
            const FieldSpec('resolution', 'Follow-up / resolution note',
                multiline: true, required: false)
          ],
        EntityKind.term => [
            const FieldSpec('start', 'Start date (YYYY-MM-DD)',
                initial: '2027-01-13'),
            const FieldSpec('end', 'End date (YYYY-MM-DD)',
                initial: '2027-03-26'),
            const FieldSpec('status', 'Status',
                options: ['Active'], initial: 'Active')
          ],
        _ => [],
      }
    ];
