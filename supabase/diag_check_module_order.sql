select sort_order, title
from public.formation_course_modules
where course_id = (
  select id from public.formation_courses
  where title ilike '%liquide vaisselle%'
)
order by sort_order;
