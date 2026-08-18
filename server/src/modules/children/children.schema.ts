import { z } from "zod";

export const childGenderSchema = z.enum(["MALE", "FEMALE", "OTHER"]);

export const createChildSchema = z.object({
  nickname: z.string().min(1, "이름(애칭)을 입력해주세요.").max(30),
  gender: childGenderSchema.optional(),
  birthDate: z.coerce.date({ message: "생년월일을 올바르게 입력해주세요." }),
});
export type CreateChildInput = z.infer<typeof createChildSchema>;

export const updateChildSchema = createChildSchema;
export type UpdateChildInput = z.infer<typeof updateChildSchema>;
