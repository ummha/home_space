<script setup lang="ts">
import type { Post } from '~/stores/posts'

interface StatusBadgeProps {
  status: Post['status']
}

const props = defineProps<StatusBadgeProps>()

const variantMap = {
  draft: 'secondary',
  published: 'success',
  archived: 'outline',
} as const

const labelMap = {
  draft: 'Draft',
  published: 'Published',
  archived: 'Archived',
} as const
</script>

<template>
  <Badge :variant="variantMap[status]">
    {{ labelMap[status] }}
  </Badge>
</template>
