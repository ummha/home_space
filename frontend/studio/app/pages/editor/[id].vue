<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { usePostsStore } from '~/stores/posts'
import type { Post } from '~/stores/posts'

const route = useRoute()
const router = useRouter()
const postsStore = usePostsStore()

definePageMeta({
  layout: 'default',
})

const postId = computed(() => route.params.id as string)
const isNew = computed(() => postId.value === 'new')

const title = ref('')
const slug = ref('')
const content = ref('')
const excerpt = ref('')
const category = ref('')
const tags = ref('')
const status = ref<Post['status']>('draft')

const showPreview = ref(true)

onMounted(() => {
  if (!isNew.value) {
    const post = postsStore.getPostById(postId.value)
    if (post) {
      title.value = post.title
      slug.value = post.slug
      content.value = post.content
      excerpt.value = post.excerpt || ''
      category.value = post.category || ''
      tags.value = post.tags?.join(', ') || ''
      status.value = post.status
    } else {
      router.push('/')
    }
  }
})

const handleSave = (shouldPublish = false) => {
  const postData = {
    title: title.value,
    slug: slug.value || generateSlug(title.value),
    content: content.value,
    excerpt: excerpt.value,
    category: category.value,
    tags: tags.value.split(',').map(t => t.trim()).filter(Boolean),
    status: shouldPublish ? 'published' as const : status.value,
    ...(shouldPublish && { publishedAt: new Date().toISOString() }),
  }

  if (isNew.value) {
    const newPost = postsStore.createPost(postData)
    router.push(`/editor/${newPost.id}`)
  } else {
    postsStore.updatePost(postId.value, postData)
  }
}

const generateSlug = (text: string) => {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9가-힣]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

const handleCancel = () => {
  if (confirm('변경사항을 저장하지 않고 나가시겠습니까?')) {
    router.push('/')
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- Editor Header -->
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-3xl font-bold tracking-tight">
          {{ isNew ? '새 글 작성' : '글 수정' }}
        </h2>
        <p class="text-muted-foreground mt-2">
          마크다운으로 작성하고 실시간으로 미리보기를 확인하세요
        </p>
      </div>
      <div class="flex gap-2">
        <Button variant="outline" @click="handleCancel">
          <Icon name="lucide:x" class="w-4 h-4 mr-2" />
          취소
        </Button>
        <Button variant="outline" @click="handleSave(false)">
          <Icon name="lucide:save" class="w-4 h-4 mr-2" />
          임시저장
        </Button>
        <Button @click="handleSave(true)">
          <Icon name="lucide:send" class="w-4 h-4 mr-2" />
          게시
        </Button>
      </div>
    </div>

    <!-- Editor Content -->
    <div class="grid gap-6 lg:grid-cols-3">
      <!-- Main Editor Area -->
      <div class="lg:col-span-2 space-y-4">
        <!-- Title and Metadata -->
        <Card>
          <CardContent class="pt-6 space-y-4">
            <div>
              <label class="text-sm font-medium mb-2 block">제목</label>
              <Input 
                v-model="title" 
                placeholder="게시글 제목을 입력하세요"
                class="text-lg"
              />
            </div>
            
            <div>
              <label class="text-sm font-medium mb-2 block">슬러그</label>
              <Input 
                v-model="slug" 
                placeholder="URL 슬러그 (자동 생성됨)"
              />
            </div>

            <div>
              <label class="text-sm font-medium mb-2 block">요약</label>
              <Textarea 
                v-model="excerpt" 
                placeholder="게시글 요약 (선택사항)"
                rows="2"
              />
            </div>
          </CardContent>
        </Card>

        <!-- Markdown Editor -->
        <Card class="flex flex-col" style="height: 600px;">
          <CardHeader class="flex flex-row items-center justify-between pb-3">
            <CardTitle class="text-lg">마크다운 에디터</CardTitle>
            <Button 
              variant="outline" 
              size="sm"
              @click="showPreview = !showPreview"
            >
              <Icon :name="showPreview ? 'lucide:eye-off' : 'lucide:eye'" class="w-4 h-4 mr-2" />
              {{ showPreview ? '미리보기 숨김' : '미리보기 표시' }}
            </Button>
          </CardHeader>
          <CardContent class="flex-1 p-0 overflow-hidden">
            <div class="grid h-full" :class="showPreview ? 'grid-cols-2' : 'grid-cols-1'">
              <div class="h-full border-r">
                <MarkdownEditor v-model="content" />
              </div>
              <div v-if="showPreview" class="h-full overflow-auto">
                <MarkdownPreview :content="content" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- Sidebar -->
      <div class="space-y-4">
        <Card>
          <CardHeader>
            <CardTitle class="text-lg">게시 설정</CardTitle>
          </CardHeader>
          <CardContent class="space-y-4">
            <div>
              <label class="text-sm font-medium mb-2 block">카테고리</label>
              <Input 
                v-model="category" 
                placeholder="예: Tutorial, Development"
              />
            </div>

            <div>
              <label class="text-sm font-medium mb-2 block">태그</label>
              <Input 
                v-model="tags" 
                placeholder="쉼표로 구분 (예: vue, nuxt, web)"
              />
              <p class="text-xs text-muted-foreground mt-1">
                쉼표로 구분하여 입력하세요
              </p>
            </div>

            <div>
              <label class="text-sm font-medium mb-2 block">상태</label>
              <div class="flex gap-2">
                <StatusBadge :status="status" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle class="text-lg">마크다운 가이드</CardTitle>
          </CardHeader>
          <CardContent class="space-y-2 text-sm">
            <div>
              <code class="bg-muted px-2 py-1 rounded"># 제목</code>
              <p class="text-muted-foreground text-xs mt-1">헤딩 1</p>
            </div>
            <div>
              <code class="bg-muted px-2 py-1 rounded">**굵게**</code>
              <p class="text-muted-foreground text-xs mt-1">볼드 텍스트</p>
            </div>
            <div>
              <code class="bg-muted px-2 py-1 rounded">*기울임*</code>
              <p class="text-muted-foreground text-xs mt-1">이탤릭 텍스트</p>
            </div>
            <div>
              <code class="bg-muted px-2 py-1 rounded">[링크](url)</code>
              <p class="text-muted-foreground text-xs mt-1">하이퍼링크</p>
            </div>
            <div>
              <code class="bg-muted px-2 py-1 rounded">- 항목</code>
              <p class="text-muted-foreground text-xs mt-1">목록</p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  </div>
</template>
