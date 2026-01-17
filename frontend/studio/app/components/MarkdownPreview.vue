<script setup lang="ts">
import { computed } from 'vue'
import MarkdownIt from 'markdown-it'

interface MarkdownPreviewProps {
  content: string
}

const props = defineProps<MarkdownPreviewProps>()

const md = new MarkdownIt({
  html: true,
  linkify: true,
  typographer: true,
})

const renderedContent = computed(() => {
  if (!props.content) {
    return '<p class="text-muted-foreground italic">Preview will appear here...</p>'
  }
  return md.render(props.content)
})
</script>

<template>
  <div class="h-full overflow-auto p-6 bg-background">
    <div 
      class="prose prose-slate dark:prose-invert max-w-none"
      v-html="renderedContent"
    />
  </div>
</template>

<style scoped>
.prose {
  color: hsl(var(--color-foreground));
}

.prose :deep(h1) {
  font-size: 1.875rem;
  font-weight: 700;
  margin-top: 2rem;
  margin-bottom: 1rem;
}

.prose :deep(h2) {
  font-size: 1.5rem;
  font-weight: 700;
  margin-top: 1.5rem;
  margin-bottom: 0.75rem;
}

.prose :deep(h3) {
  font-size: 1.25rem;
  font-weight: 700;
  margin-top: 1rem;
  margin-bottom: 0.5rem;
}

.prose :deep(p) {
  margin-bottom: 1rem;
  line-height: 1.75;
}

.prose :deep(a) {
  color: hsl(var(--color-primary));
  text-decoration: underline;
}

.prose :deep(code) {
  background-color: hsl(var(--color-muted));
  padding: 0.125rem 0.375rem;
  border-radius: 0.25rem;
  font-size: 0.875rem;
  font-family: monospace;
}

.prose :deep(pre) {
  background-color: hsl(var(--color-muted));
  padding: 1rem;
  border-radius: 0.5rem;
  overflow-x: auto;
  margin-bottom: 1rem;
}

.prose :deep(pre code) {
  background-color: transparent;
  padding: 0;
}

.prose :deep(ul), .prose :deep(ol) {
  margin-bottom: 1rem;
  padding-left: 1.5rem;
}

.prose :deep(li) {
  margin-bottom: 0.5rem;
}

.prose :deep(blockquote) {
  border-left: 4px solid hsl(var(--color-muted-foreground) / 0.3);
  padding-left: 1rem;
  font-style: italic;
  margin: 1rem 0;
}

.prose :deep(img) {
  border-radius: 0.5rem;
  margin: 1rem 0;
}

.prose :deep(table) {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 1rem;
}

.prose :deep(th) {
  border: 1px solid hsl(var(--color-border));
  background-color: hsl(var(--color-muted));
  padding: 0.5rem;
  text-align: left;
  font-weight: 600;
}

.prose :deep(td) {
  border: 1px solid hsl(var(--color-border));
  padding: 0.5rem;
}
</style>
